import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    private var collectionView: UICollectionView!
    private var segmentedControl: UISegmentedControl!
    private var startButton: UIButton!
    private var resultLabel: UILabel!
    private var progressView: UIProgressView!
    private var cancelButton: UIButton!
    
    private var images: [UIImage] = []
    private var processingTask: Task<Void, Never>?
    private var totalOperations: Int = 0
    private var completedOperations: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImages()
    }
    
    private func setupUI() {
        view.backgroundColor = .white

        segmentedControl = UISegmentedControl(items: ["Параллельно", "Последовательно"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100) // Set appropriate size
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        startButton = UIButton(type: .system)
        startButton.setTitle("Начать обработку", for: .normal)
        startButton.addTarget(self, action: #selector(startComputations), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)
        
        resultLabel = UILabel()
        resultLabel.textAlignment = .center
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultLabel)
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Отмена", for: .normal)
        cancelButton.isHidden = true
        cancelButton.addTarget(self, action: #selector(cancelProcessing), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 400),
            
            startButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            resultLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func loadImages() {
        images.append(UIImage(named: "image1")!)
        images.append(UIImage(named: "image2")!)
        images.append(UIImage(named: "image3")!)
        images.append(UIImage(named: "image4")!)
        images.append(UIImage(named: "image5")!)
        images.append(UIImage(named: "image6")!)
        images.append(UIImage(named: "image7")!)
        images.append(UIImage(named: "image8")!)
        images.append(UIImage(named: "image9")!)
        images.append(UIImage(named: "image10")!)
    }

    func applyRandomFilter(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filters: [CIFilter] = [
          CIFilter(name: "CIBloom")!,
          CIFilter(name: "CISepiaTone")!,
          CIFilter(name: "CIColorInvert")!,
          CIFilter(name: "CIExposureAdjust")!,
          CIFilter(name: "CIGaussianBlur")!
        ]
        let randomFilter = filters.randomElement()!

        randomFilter.setValue(ciImage, forKey: kCIInputImageKey)

        switch randomFilter.name {
        case "CIBloom":
          randomFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        case "CISepiaTone":
          randomFilter.setValue(0.8, forKey: kCIInputIntensityKey)
        case "CIExposureAdjust":
          randomFilter.setValue(0.5, forKey: "inputEV")
        case "CIGaussianBlur":
          randomFilter.setValue(5.0, forKey: kCIInputRadiusKey)
        default:
          break
        }

        guard let outputImage = randomFilter.outputImage else { return nil }
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
          return UIImage(cgImage: cgImage)
        }
        return nil
      }
    
    @objc private func startComputations() {
        startButton.isEnabled = false
        cancelButton.isHidden = false
        resultLabel.text = ""
        progressView.progress = 0.0
        totalOperations = images.count
        completedOperations = 0
        
        let isParallel = segmentedControl.selectedSegmentIndex == 0
        
        processingTask = Task {
            if isParallel {
                await processImagesParallel()
            } else {
                await processImagesSequentially()
            }
            
            DispatchQueue.main.async {
                self.startButton.isEnabled = true
                self.cancelButton.isHidden = true
                self.progressView.progress = 1.0
            }
        }
    }

    private func processImage(_ image: UIImage) async {
      try? await Task.sleep(nanoseconds: 500_000_000)

      if let filteredImage = applyRandomFilter(to: image) {
        DispatchQueue.main.async {
          if let index = self.images.firstIndex(where: {$0 == image}) {
            self.images[index] = filteredImage
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
          }
          
          self.completedOperations += 1
          self.progressView.progress = Float(self.completedOperations) / Float(self.totalOperations)
        }
      } else {
        print("ащибка наложения фильтров") // чекаем почему сломалось
      }
    }
    
    private func processImagesParallel() async {
      await withTaskGroup(of: Void.self) { group in
        for image in images {
          group.addTask {
            await self.processImage(image)
          }
        }

        for await _ in group {
          if Task.isCancelled {
            return
          }
        }
      }
      resultLabel.text = "Обработка завершена параллельно"
    }


    private func processImagesSequentially() async {
        for image in images {
            if Task.isCancelled {
                return
            }
            await processImage(image)
        }
        resultLabel.text = "Обработка завершена последовательно"
    }

    @objc private func cancelProcessing() {
        processingTask?.cancel()
        resultLabel.text = "Обработка отменена"
        progressView.progress = 0.0
        startButton.isEnabled = true
        cancelButton.isHidden = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }
        cell.imageView.image = images[indexPath.row]
        return cell
    }
}
