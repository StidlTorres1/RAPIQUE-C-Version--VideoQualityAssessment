#ifndef IMODELFACTORY_H
#define IMODELFACTORY_H

#include "IModel.h"
#include <memory>

class IModelFactory {
public:
    virtual std::unique_ptr<IModel> createModel(const std::string& modelPath) = 0;
    virtual ~IModelFactory() {}
};

#endif // IMODELFACTORY_H
