//
//  RoomRouting.swift
//  Room
//

import Entities

public protocol RoomRouting: AnyObject {
    func didLeaveRoom()
    func didStartMeet(_ meet: Meet)
}
