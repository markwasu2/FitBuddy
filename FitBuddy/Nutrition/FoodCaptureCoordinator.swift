import SwiftUI
import PhotosUI
import Combine

final class FoodCaptureCoordinator: ObservableObject, Identifiable {
    let id = UUID()
    @Published var image: UIImage?
    @Published var isPresented = false
    var onImagePicked: ((UIImage) -> Void)?

    var view: some View {
        ImagePickerView(isPresented: Binding(
            get: { self.isPresented },
            set: { self.isPresented = $0 }
        ), onImagePicked: { img in
            self.image = img
            self.onImagePicked?(img)
        })
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        if !isPresented { uiViewController.dismiss(animated: true) }
    }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView
        init(_ parent: ImagePickerView) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let img = image as? UIImage { DispatchQueue.main.async { self.parent.onImagePicked(img) } }
            }
        }
    }
} 