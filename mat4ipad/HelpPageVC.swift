//
//  HelpPageVC.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/04.
//  Copyright © 2020 ingun37. All rights reserved.
//

import SwiftUI

struct HelpPageVC: UIViewControllerRepresentable {
    func makeCoordinator() -> HelpPageVC.Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        vc.dataSource = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ vc: UIPageViewController, context: Context) {
        
        vc.setViewControllers([context.coordinator.vcs[0]], direction: .forward, animated: true)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource {
        let vcs = [UIColor.red, UIColor.green].map { (c) -> UIViewController in
            let vc = UIViewController()
            vc.view.backgroundColor = c
            return vc
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = vcs.firstIndex(of: viewController) else {
                return nil
            }
            if index == 0 {
                return vcs.last
            }
            return vcs[index - 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController) -> UIViewController?
        {
            guard let index = vcs.firstIndex(of: viewController) else {
                return nil
            }
            if index + 1 == vcs.count {
                return vcs.first
            }
            return vcs[index + 1]
        }
    }
}
