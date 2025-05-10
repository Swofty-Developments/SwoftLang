# cleanup.ps1
# This script completely cleans all Gradle caches and rebuilds your project

Write-Host "Cleaning Gradle caches and project..." -ForegroundColor Cyan

# Set Java environment variables
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
$env:PATH = "$env:JAVA_HOME\bin;" + $env:PATH

Write-Host "Using Java home: $env:JAVA_HOME"
Write-Host "Java version in use:"
& java -version

# Stop Gradle daemon
Write-Host "`nStopping any running Gradle daemons..."
& .\gradlew --stop

# Clean ALL Gradle caches
Write-Host "`nCleaning ALL Gradle caches..."
$gradleCachePath = "C:\Users\$env:USERNAME\.gradle\caches"
if (Test-Path $gradleCachePath) {
    Remove-Item -Recurse -Force $gradleCachePath -ErrorAction SilentlyContinue
    Write-Host "Removed $gradleCachePath"
}

# Clean VS Code Java extension cache
Write-Host "`nCleaning VS Code Java extension caches..."
$vscodeStoragePath = "C:\Users\$env:USERNAME\AppData\Roaming\Code\User\workspaceStorage"
if (Test-Path $vscodeStoragePath) {
    Get-ChildItem -Path $vscodeStoragePath -Directory | ForEach-Object {
        $oracleJavaPath = Join-Path $_.FullName "Oracle.oracle-java"
        if (Test-Path $oracleJavaPath) {
            Remove-Item -Recurse -Force $oracleJavaPath -ErrorAction SilentlyContinue
            Write-Host "Removed $oracleJavaPath"
        }
    }
}

# Clean project build directories
Write-Host "`nCleaning project build directories..."
$buildDirs = @(
    ".\build",
    ".\java\build",
    ".\native\build",
    ".\.gradle"
)

foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
        Write-Host "Removed $dir"
    }
}

# Create a fresh gradle.properties
Write-Host "`nCreating fresh gradle.properties..."
$gradlePropertiesContent = @"
org.gradle.java.home=C:\\Program Files\\Java\\jdk-21
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.caching=false
"@
$gradlePropertiesContent | Out-File -FilePath "gradle.properties" -Encoding utf8
Write-Host "Created gradle.properties"

# Create a fresh init script
Write-Host "`nCreating fresh init script..."
$initScriptContent = @"
initscript {
    repositories {
        gradlePluginPortal()
    }
}

allprojects {
    beforeEvaluate { project ->
        project.setProperty("org.gradle.java.home", "C:/Program Files/Java/jdk-21")
    }
    
    tasks.withType(JavaCompile).configureEach {
        options.fork = true
        options.forkOptions.javaHome = file("C:/Program Files/Java/jdk-21")
    }
    
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
        kotlinOptions.jvmTarget = "21"
    }
}
"@
$initScriptContent | Out-File -FilePath "init.gradle" -Encoding utf8
Write-Host "Created init.gradle"

# Now build with clean environment
Write-Host "`nBuilding project with clean environment..." -ForegroundColor Green
try {
    & .\gradlew --no-daemon `
      --no-configuration-cache `
      --refresh-dependencies `
      --init-script init.gradle `
      clean build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nBuild successful!" -ForegroundColor Green
    } else {
        Write-Host "`nBuild failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "`nBuild failed with error: $_" -ForegroundColor Red
}