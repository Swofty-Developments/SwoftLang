#include <ASTNode.h>
#include <string>

class Statement : public ASTNode {
    public:
        virtual std::string toJson() const = 0;
    };