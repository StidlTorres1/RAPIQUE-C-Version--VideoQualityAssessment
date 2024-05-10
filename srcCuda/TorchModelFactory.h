#ifndef TORCHMODELFACTORY_H
#define TORCHMODELFACTORY_H

#include "IModelFactory.h"
#include "TorchModel.h"

class TorchModelFactory : public IModelFactory {
public:
    std::unique_ptr<IModel> createModel(const std::string& modelPath) override {
        return std::make_unique<TorchModel>(modelPath);
    }
};

#endif // TORCHMODELFACTORY_H
