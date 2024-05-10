//#include <torch/script.h> // One-stop header.

#include <iostream>
#include <memory>

int mainTest_LibTorch(int argc, const char* argv[]) {
    //torch::jit::Module module;
    //// "C:\\Users\\MichaelGY\\Documents\\GitHub\\RAPIQUEE\\RAPIQUE-VideoQualityAssessment\\pytorch\\traced_resnet50_model.pt"
    //std::string file("./traced_resnet50_model.pt");
    //
    ////torch::Device device(torch::kCUDA);
    //std::cout << "Count ";
    //try {
    //    if (argc == 2) {
    //        // Deserialize the ScriptModule from a file using torch::jit::load().
    //        module = torch::jit::load(argv[1]);
    //    }
    //    else {
    //        std::cout << "Loading " << file << std::endl;
    //        std::ifstream ifs(file, std::ios::binary);
    //        module = torch::jit::load(ifs);
    //        std::cout << "Loaded!!!"<< std::endl;

    //        // Create a vector of inputs.
    //        std::vector<torch::jit::IValue> inputs;
    //        inputs.push_back(torch::ones({ 1, 3, 224, 224 }));

    //        // Execute the model and turn its output into a tensor.
    //        module.forward(inputs);
    //        // at::Tensor output = ;
    //        // std::cout << output.slice(/*dim=*/1, /*start=*/0, /*end=*/5) << '\n';
    //    }
    //}
    //catch (const c10::Error& e) {
    //    std::cerr << "error loading the model " << file << std::endl;
    //    std::cerr << "what: " << e.what() << std::endl;
    //    return -1;
    //}

    //std::cout << "ok\n";

    return 0;
}