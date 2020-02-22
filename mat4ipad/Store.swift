//
//  Store.swift
//  mat4ipad
//
//  Created by Ingun Jon on 2020/02/22.
//  Copyright © 2020 ingun37. All rights reserved.
//

import Foundation
import ReSwift

public struct TooltipState: StateType {
    var applyTipShown: Bool = false
}

public struct ApplyTipShownAction: Action {}

public func tooltipReducer(action: Action, state: TooltipState?)->TooltipState {
    var state = state ?? TooltipState()
    switch action {
    case _ as ApplyTipShownAction:
        state.applyTipShown = true
    default:
        break
    }
    return state
}

public let tooltipStore = Store<TooltipState>(
    reducer: tooltipReducer,
    state: nil
)
