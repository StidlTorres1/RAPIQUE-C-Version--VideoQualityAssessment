import torch
import torchvision
print(torch.version.cuda)

# An instance of your model.
model = torchvision.models.resnet50()

# An example input you would normally provide to your model's forward() method.
example = torch.rand(1, 3, 224, 224)

# Use torch.jit.trace to generate a torch.jit.ScriptModule via tracing.
traced_script_module = torch.jit.trace(model, example)

output = traced_script_module(torch.ones(1, 3, 224, 224))

#traced_script_module.save("traced_resnet_model.pt")

traced_script_module.save("traced_resnet50_model.pt")
traced_script_module_file = torch.jit.load("traced_resnet50_model.pt")

output_file = traced_script_module_file(torch.ones(1, 3, 224, 224))

