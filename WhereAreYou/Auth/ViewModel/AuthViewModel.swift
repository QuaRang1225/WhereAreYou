//
//  AuthViewModel.swift
//  WhereAreYou
//
//  Created by 유영웅 on 2023/07/08.
//

import Foundation
import PhotosUI
import SwiftUI
import Combine

@MainActor
final class AuthViewModel:ObservableObject{
    
    @Published var user:UserData? = nil
    @Published var infoSetting:InfoSettingFilter = .nickname
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var selectedImageData: Data? = nil
    
    var changedSuccess = PassthroughSubject<(),Never>()
    
    func signUp(email:String,password:String) async throws{
        do{
            let authUser = try await AuthManager.shared.createUser(email: email, password: password) //값을 굳이 안쓰고 컴파일러에 값이 있을
            user = UserData(auth: authUser)
            try UserManager.shared.createNewUser(user: user!)
            print("가입 성공")
        }catch{
            print("에러 발생: \(error)")
        }
    }
    func signIn(email: String, password: String) async throws {
        do {
            let authUser = try await AuthManager.shared.signInUser(email: email, password: password)
            user = try await UserManager.shared.getUser(userId: authUser.uid)
            print("인증 성공")
        } catch {
            print("에러 발생: \(error.localizedDescription)")
        }
    }
    func updateNickname(userId:String,text:String){
        Task{
            try await UserManager.shared.updateUsetNickname(userId:userId,text:text)
            self.user = try await UserManager.shared.getUser(userId: userId)
            changedSuccess.send()
        }
    }
    func saveProfileImage(item:PhotosPickerItem){
        guard var user else {return}
        
        Task{
            guard let data = try await item.loadTransferable(type: Data.self) else {return}
           
            let path = try await StorageManager.shared.saveImage(data:data,userId: user.userId, mode: .profile)
            let url = try await StorageManager.shared.getUrlForImage(path: path)
            user.guestMode = false
            try UserManager.shared.createNewUser(user: user)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path,url: url.absoluteString)
            
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    func deleteProfileImage(){
        guard let user,let path = user.profileImagePath else {return}
        
        Task{
            try await StorageManager.shared.deleteImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: nil, url: nil)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
            changedSuccess.send()
        }
    }
    func updateProfileImage(item:PhotosPickerItem){
        guard let user else {return}
        Task{
            
            if let path = user.profileImagePath{
                try await StorageManager.shared.deleteImage(path: path)
            }
            
            guard let data = try await item.loadTransferable(type: Data.self) else {return}
            let path = try await StorageManager.shared.saveImage(data:data,userId: user.userId, mode: .profile)
            let url = try await StorageManager.shared.getUrlForImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path,url: url.absoluteString)
            
           
            self.user = try await UserManager.shared.getUser(userId: user.userId)
            changedSuccess.send()
        }
    }
    func noImageSave(){
        Task{
            guard let user,let path = user.profileImagePath else {return}
            try await StorageManager.shared.deleteImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: nil,url:CustomDataSet.shared.images.randomElement())
            self.user = try await UserManager.shared.getUser(userId: user.userId)
            changedSuccess.send()
        }
    }
    
    
    func logOut(){
        try? AuthManager.shared.signOut()
        user = nil
    }
    func delete(){
        Task{
            try? await AuthManager.shared.delete()
            user = nil
        }
    }
    func getUser(auth:AuthData){
        Task{
            user = try await UserManager.shared.getUser(userId: auth.uid)
        }
    }
}
