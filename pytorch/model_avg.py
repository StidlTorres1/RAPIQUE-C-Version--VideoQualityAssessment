import torch
import torchvision.models as models

# Cargar el modelo preentrenado
model = models.resnet50(pretrained=True)

# Modificar el modelo para que la última capa sea avg_pool
# Esto depende de la arquitectura exacta del modelo. Para ResNet50:
model = torch.nn.Sequential(*(list(model.children())[:-2]))
input_tensor = torch.rand(1, 3, 224, 224)  # Tamaño de entrada típico para ResNet

# Trazar el modelo
traced_model = torch.jit.trace(model, input_tensor)

# Guardar el modelo trazado
traced_model.save("traced_resnet50_avg_pool.pt")