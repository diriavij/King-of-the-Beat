import Foundation

protocol ResultsBusinessLogic {
    func fetchTopThree(completion: @escaping ([Track]) -> Void)
    func fetchAllSongs(completion: @escaping ([Track]) -> Void)
}

protocol ResultsPresentationLogic {
    
}
