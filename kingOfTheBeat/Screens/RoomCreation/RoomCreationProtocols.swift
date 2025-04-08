import Foundation

protocol RoomCreationBusinessLogic {
    func loadMainScreen(_ request: RoomCreationModels.RouteToMain.Request)
    func createRoom(_ request: RoomCreationModels.CreateRoom.Request)
}

protocol RoomCreationPresentationLogic {
    func routeToMainScreen(_ response: RoomCreationModels.RouteToMain.Response)
    func routeToRoomScreen(_ response: RoomCreationModels.CreateRoom.Response)
}
