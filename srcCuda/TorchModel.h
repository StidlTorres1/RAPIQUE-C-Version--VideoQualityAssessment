#ifndef TORCHMODEL_H
#define TORCHMODEL_H

#include "IModel.h"
#include <iostream>

class TorchModel : public IModel {
private:
    torch::jit::Module module_;

public:
    TorchModel(const std::string& modelPath) {
        try {
            module_ = torch::jit::load(modelPath);
            std::cout << "Model loaded successfully." << std::endl;
        }
        catch (const c10::Error& e) {
            std::cerr << "Error loading the model: " << e.what() << std::endl;
            throw;
        }
    }

    torch::jit::Module getModule() const override {
        return module_;
    }
};

#endif // TORCHMODEL_H
