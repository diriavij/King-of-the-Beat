import UIKit
import WebKit

final class IntroViewController: UIViewController {
    
    // MARK: - Constants and Variables
    
    internal let appNameLabel = UILabel()
    internal let upperShining = UIImageView()
    internal let lowerShining = UIImageView()
    internal let welcomeLabel = UILabel()
    internal let labelsStackView = UIStackView()
    internal let buttonStackView = UIStackView()
    internal let joinLabel = UILabel()
    internal let joinButton = UIButton(type: .system)
    
    private var interactor: IntroBusinessLogic
    
    public var authWebView: UIViewController?

    internal enum Const {
        static let appName: String = "KING\nof the\nBEAT"
        static let titleLightColor: String = "90A679"
        static let welcomeMessage: String = "Welcome to"
    }

    // MARK: - Lifecycle
    init(interactor: IntroInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Configuring Methods
    private func configureUI() {
        configureShining()
        configureLabels()
        configureButton()
    }

    private func configureLabels() {
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .center
        labelsStackView.spacing = 20
        
        appNameLabel.numberOfLines = 3
        let mas = NSMutableAttributedString(string: Const.appName)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineHeightMultiple = 0.5
        mas.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, mas.length))
        appNameLabel.attributedText = mas
        appNameLabel.textAlignment = .center
        appNameLabel.font = UIFont(name: "Modak", size: 80)
        appNameLabel.textColor = UIColor.convertToRGBInit(Const.titleLightColor)
        appNameLabel.adjustsFontSizeToFitWidth = true
        appNameLabel.minimumScaleFactor = 0.5
        appNameLabel.setHeight(250)
        
        welcomeLabel.text = Const.welcomeMessage
        welcomeLabel.font = UIFont.systemFont(ofSize: 28)
        welcomeLabel.textColor = UIColor.convertToRGBInit(Const.titleLightColor)
        welcomeLabel.textAlignment = .center
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.minimumScaleFactor = 0.5
        
        labelsStackView.addArrangedSubview(welcomeLabel)
        labelsStackView.addArrangedSubview(appNameLabel)
        
        view.addSubview(labelsStackView)
        labelsStackView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 50)
        labelsStackView.pinCenterX(to: view)
    }
    
    private func configureButton() {
        joinButton.setTitle("Spotify", for: .normal)
        joinButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: UIFont.Weight(5))
        joinButton.setTitleColor(.black, for: .normal)
        joinButton.layer.cornerRadius = 25
        joinButton.addTarget(self, action: #selector(buttonWasPressed), for: .touchUpInside)
        view.addSubview(joinButton)
        joinButton.pinHeight(to: view.heightAnchor, 0.06)
        joinButton.pinWidth(to: view.widthAnchor, 0.6)
        joinButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, 250)
        joinButton.pinCenterX(to: view)
        joinButton.backgroundColor = UIColor.convertToRGBInit(Const.titleLightColor)
        
        joinLabel.text = "Join us via"
        joinLabel.textColor = UIColor.convertToRGBInit(Const.titleLightColor)
        joinLabel.font = UIFont.systemFont(ofSize: 24)
        joinLabel.textAlignment = .center
        view.addSubview(joinLabel)
        joinLabel.pinCenterX(to: view)
        joinLabel.pinBottom(to: joinButton.topAnchor, 10)
    }
    
    private func configureShining() {
        upperShining.image = UIImage(named: "shining_top")
        view.addSubview(upperShining)
        upperShining.pinTop(to: view.topAnchor)
        upperShining.pinCenterX(to: view)
        upperShining.pinWidth(to: view)
        upperShining.pinHeight(to: view, 0.5)
        
        lowerShining.image = UIImage(named: "shining_bottom")
        view.addSubview(lowerShining)
        lowerShining.pinBottom(to: view.bottomAnchor)
        lowerShining.pinCenterX(to: view)
        lowerShining.pinWidth(to: view)
        lowerShining.pinHeight(to: view, 0.5)
    }
    
    // MARK: - Actions
    
    @objc
    private func buttonWasPressed() {
        interactor.getAuthToken(IntroModels.Auth.Request())
    }
    
    private func tokenReceived() {
        interactor.loadMain(IntroModels.Route.Request())
    }

}

extension IntroViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        guard let urlString = webView.url?.absoluteString else { return }
        var code = ""
        print(urlString)
        if urlString.contains("code=") {
            let range = urlString.range(of: "code=")
            guard let index = range?.upperBound else { return }
            code = String(urlString[index...])
            UserDefaults.standard.set(code, forKey: "Code")
            let helper = APIService()
            helper.getAccessToken { result in
                
            }
            authWebView?.dismiss(animated: true)
            tokenReceived()
        }
    }
}

