//
//  Signal.swift
//  Silkscreen
//
//  Created by James Campbell on 4/26/16.
//  Copyright © 2016 SK. All rights reserved.
//

import Foundation

// - Simplify API with Sender value
class Signal<T> {
    
    let sender: T
    fileprivate var slots = Frozen<[Slot<T>]>(value: [])
    
    init(sender: T) {
        self.sender = sender
    }
    
    func trigger() {
        slots.value.forEach {
            $0.callback?(sender)
        }
    }
    
    func addSlot(_ callback: @escaping (_ sender: T) -> Void) -> Slot<T> {
        let slot = Slot(signal: self)
        slot.callback = callback
        slot.callback?(sender)
    
        slots = slots.append(slot)
        return slot
    }
    
    func removeSlot(_ slot: Slot<T>) {
        
        let newSlots = slots.value.filter {
            $0.signalID != slot.signalID
        }
        
        slots = Frozen(value: newSlots)
    }
}
