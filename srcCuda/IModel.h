#ifndef IMODEL_H
#define IMODEL_H

#include <torch/script.h>

class IModel {
public:
    virtual torch::jit::Module getModule() const = 0;
    virtual ~IModel() {}
};

#endif // IMODEL_H
