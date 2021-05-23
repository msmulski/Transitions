//
//  ViewController.swift
//  Transitions
//
//  Created by Michał Smulski on 21/05/2021.
//

import UIKit
import Combine

@resultBuilder
struct ConstraintsBuilder {
    static func buildBlock(_ components: NSLayoutConstraint...) -> [NSLayoutConstraint] {
        components
    }
    
}

extension NSLayoutConstraint {
    static func activate(@ConstraintsBuilder content: () -> [NSLayoutConstraint]) {
        activate(content())
    }
}

extension UIViewPropertyAnimator {
    func start() -> Future<Void, Never> {
        return Future<Void, Never> { [weak self] promise in
            self?.addCompletion { _ in
                promise(.success(()))
            }
            self?.startAnimation()
        }
    }
}

enum Edges: Hashable, Equatable {
    case leading
    case top
    case trailing
    case bottom
}

class ViewController: UIViewController {
    let container: UIViewController = {
        let controller = UIViewController()
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .systemTeal
        return controller
    }()
    var visibileController: UIViewController?
    var sink: Set<AnyCancellable> = []
    let blurView = UIBlurEffect(style: .dark)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Container"
        view.backgroundColor = .black.withAlphaComponent(0.3)
        addContainer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.addA()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.removeVisibleController()
                self.addB()
            }
        }
    }
    
    func addContainer() {
        container.willMove(toParent: self)
        view.addSubview(container.view)
        container.didMove(toParent: self)
        
        NSLayoutConstraint.activate {
            view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor)
            container.view.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 0.0)
            view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor)
            view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor)
        }
    }
    
    func removeVisibleController() {
        guard let visible = visibileController else { return }
        
        visible.view.removeFromSuperview()
        visible.removeFromParent()
        visibileController = nil
    }
    
    func addA() {
        let controller = ControllerA()
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.alpha = 0.0
        
        controller.willMove(toParent: container)
        container.view.addSubview(controller.view)
        controller.didMove(toParent: container)
        
        animate(controller: controller)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func addB() {
        let controller = ControllerB()
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.alpha = 0.0
        
        controller.willMove(toParent: container)
        container.view.addSubview(controller.view)
        controller.didMove(toParent: container)
        
        animate(controller: controller)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func animate(controller: UIViewController) {
        NSLayoutConstraint.activate {
            container.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor)
            container.view.topAnchor.constraint(equalTo: controller.view.topAnchor)
            container.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
            container.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        }
        
        let alphaAnimator = UIViewPropertyAnimator(duration: 1.0, curve: .easeOut) {
            controller.view.alpha = 1.0
        }
        let layoutAnimator = UIViewPropertyAnimator(duration: 1.0, curve: .easeOut) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        layoutAnimator.start().sink { _ in
            alphaAnimator.startAnimation()
        }.store(in: &sink)
        title = controller.title
        visibileController = controller
    }
}

class ViewA: UIView {
    override var intrinsicContentSize: CGSize {
        .init(width: CGFloat.greatestFiniteMagnitude, height: 400.0)
    }
}

class ControllerA: UIViewController {
    override func loadView() {
        view = ViewA(frame: .zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
        title = "ControllerA"
    }
}

class ViewB: UIView {
    override var intrinsicContentSize: CGSize {
        .init(width: CGFloat.greatestFiniteMagnitude, height: 600.0)
    }
}

class ControllerB: UIViewController {
    override func loadView() {
        view = ViewB(frame: .zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGreen
        title = "ControllerB"
    }
}

