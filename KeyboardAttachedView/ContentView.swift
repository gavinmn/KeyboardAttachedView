//
//  ContentView.swift
//  KeyboardAttachedView
//
//  Created by Gavin Nelson on 8/21/24.
//

//  Credit to https://techhub.social/@brandonhorst for code contributions and bug fixes
//  and to https://mastodon.social/@erichoracek for the approach

import SwiftUI
import UIKit

struct ContentView: View {
	@State private var offset: CGFloat = 0
	
	var body: some View {
		VStack(spacing: 0) {
			ScrollView {
				ForEach(0..<20) { index in
					HStack {
						Text("Item \(index + 1)")
							.padding()
						Spacer()
					}
				}
			}
            .contentMargins(.bottom, -offset)
			.scrollDismissesKeyboard(.interactively)
			.scrollClipDisabled()
			.defaultScrollAnchor(.bottom)
			TextInputView()
				.offset(y: offset)
		}
		.background {
			KeyboardAttachedView(offset: $offset)
				.frame(height: 0)
				.frame(maxHeight: .infinity, alignment: .bottom)
		}
		.ignoresSafeArea(.keyboard)
	}
}

struct TextInputView: View {
	@State private var textFieldText = ""
	var body: some View {
		TextField("Type here", text: $textFieldText)
			.textFieldStyle(RoundedBorderTextFieldStyle())
			.padding()
			.background(.white)
	}
}

struct KeyboardAttachedView: UIViewControllerRepresentable {
	var offset: Binding<CGFloat>
	
	func makeUIViewController(context: Context) -> KeyboardObservingViewController {
		let viewController = KeyboardObservingViewController(offset: offset)
		return viewController
	}
	func updateUIViewController(_ uiViewController: KeyboardObservingViewController, context: Context) {}
}

class KeyboardObservingViewController: UIViewController {
	var offset: Binding<CGFloat>
	var emptyView: UIView = UIView()
	var isKeyboardOpened: Bool = false
	
	var keyboardAnimation: Animation = .easeInOut(duration: 0.3)


	init(offset: Binding<CGFloat>) {
		self.offset = offset
		super.init(nibName: nil, bundle: nil)
		setupKeyboardNotifications()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		view.addSubview(emptyView)
		emptyView.translatesAutoresizingMaskIntoConstraints = false
		emptyView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true
		emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let newOffset = emptyView.layer.position.y
		
		if !isKeyboardOpened || abs(newOffset - offset.wrappedValue) > 100 {
			withAnimation(keyboardAnimation) {
				self.offset.wrappedValue = newOffset
			}
		} else {
			offset.wrappedValue = newOffset
		}
	}

	private func setupKeyboardNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
	}

	@objc func keyboardWillShow(notification: Notification) {
		keyboardAnimation = animation(from: notification) ?? .easeInOut(duration: 0.3)
	}
	
	func animation(from notification: Notification) -> Animation? {
		guard
		  let info = notification.userInfo,
		  let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
		  let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
		  let uiKitCurve = UIView.AnimationCurve(rawValue: curveValue)
		else {
			return nil
		}

		/// From https://gist.github.com/timothycosta/78e87544a90ce1670548407aac556ab3?permalink_comment_id=4493455#gistcomment-4493455
		
		let timing = UICubicTimingParameters(animationCurve: uiKitCurve)
		if let springParams = timing.springTimingParameters,
		   let mass = springParams.mass, let stiffness = springParams.stiffness, let damping = springParams.damping {
			return Animation.interpolatingSpring(mass: mass, stiffness: stiffness, damping: damping)
		} else {
			return Animation.easeOut(duration: duration)
		}
	}

	@objc private func keyboardDidShow(notification: Notification) {
		isKeyboardOpened = true
	}

	@objc private func keyboardDidHide(notification: Notification) {
		isKeyboardOpened = false
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}

private extension UISpringTimingParameters {
	var mass: Double? {
		value(forKey: "mass") as? Double
	}
	var stiffness: Double? {
		value(forKey: "stiffness") as? Double
	}
	var damping: Double? {
		value(forKey: "damping") as? Double
	}
}
