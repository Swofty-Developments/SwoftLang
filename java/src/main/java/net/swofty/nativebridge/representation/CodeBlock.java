package net.swofty.nativebridge.representation;

public class CodeBlock {
    private String type;
    private String code;
    
    public CodeBlock(String type, String code) {
        this.type = type;
        this.code = code;
    }
    
    public String getType() {
        return type;
    }
    
    public String getCode() {
        return code;
    }
}
