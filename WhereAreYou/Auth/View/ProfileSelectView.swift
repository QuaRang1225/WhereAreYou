//
//  ProfileSelectView.swift
//  WhereAreYou
//
//  Created by 유영웅 on 2023/07/01.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ProfileSelectView: View {
    
    @State var profile = ""
    @EnvironmentObject var vm:AuthViewModel
//    @State var modify = false
    @State var create = false //계정 만드는 중..
    @Environment(\.dismiss) var dismiss
    
    let colmun = [GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())]
    
    var body: some View {
        ZStack{
            Color.white.ignoresSafeArea()
            VStack{
//                Text(modify ? "프로필수정" : "프로필선택")
                Text("프로필선택")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(.leading)
                    .padding(.vertical,30)
                    .foregroundColor(.black)
                ScrollView {
                    
                    LazyHGrid(rows: colmun,spacing: 10){
                        ForEach(CustomDataSet.shared.images,id:\.self){ image in
                            Button {
                                vm.selectedImageData = nil
                                vm.selectedItem = nil
                                profile = image
                            } label: {
                                KFImage(URL(string:image))
                                    .resizable()
                                    .overlay{
                                        if !profile.isEmpty || vm.selectedItem != nil{
                                            if vm.selectedItem != nil || profile != image{
                                                Color.white.opacity(0.8)
                                            }
                                        }
                                       
//                                        if !profile.isEmpty{
//                                            Color.white.opacity(0.8)
//                                        }
//                                        else if profile != image {//||
////                                        if (profile != image && !profile.isEmpty) || (profile != image && vm.selectedItem != nil){
//                                            Color.white.opacity(0.8)
//                                        }else if vm.selectedItem != nil{
//                                            Color.white.opacity(0.8)
//                                        }
                                    }
                                    .frame(width: 80,height: 80)
                                    .cornerRadius(30)
                            }
                        }
                        PhotosPicker(
                            selection: $vm.selectedItem,
                            matching: .images,
                            photoLibrary: .shared()) {
                                if let selectedImageData = vm.selectedImageData,
                                   let uiImage = UIImage(data: selectedImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80,height: 80).clipShape(RoundedRectangle(cornerRadius: 30))
                                    
                                }else{
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(lineWidth: 1)
                                        .frame(width: 80,height: 80)
                                        .overlay {
                                            Image(systemName: "camera")
                                                .font(.title)
                                        }
                                        .foregroundStyle(.gray)
                                }
                            }
                            .onChange(of: vm.selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        vm.selectedImageData = data
                                    }
                                }
                            }
                        
                    }
                    .foregroundColor(.black)
                    .padding(.bottom,30)
                    
                    SelectButton(color:vm.selectedItem != nil || !profile.isEmpty ? .customCyan3 : .gray, textColor: .white, text: "확인") {
                        if let item = vm.selectedItem {
                            create = true
//                            guard let item = vm.selectedItem else { return vm.noImageSave() }
//                            if !modify{
                                vm.savePhotoProfileImage(item: item)
//                            }else{
//                                vm.updateProfileImage(item: item)
//                            }
                        }else if !profile.isEmpty,profile != "photo" {
                            create = true
                            vm.saveImageProfileImage(item: profile)
                        }
                        
                    }
//                    if !modify{
//                        Button {
//                            create = true
//                            Task{
//                                guard var user = vm.user else {return}
//                                user.guestMode = false
//                                user.profileImageUrl = CustomDataSet.shared.images.randomElement()
//                                vm.user = user
//                                try UserManager.shared.createNewUser(user: user)
//                            }
//                        } label: {
//                            Text("건너뛰기")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        .padding()
//                    }
                }
            }
            if create{
//                CustomProgressView(title: modify ? "프로필 변경 중.." : "계정 생성 중..").ignoresSafeArea()
                CustomProgressView(title: "계정 생성 중..").ignoresSafeArea()
            }
        }
        .onDisappear{
            vm.selectedItem = nil
            vm.selectedImageData = nil
        }
        .onReceive(vm.changedSuccess){
            dismiss()
        }
        
    }
}

struct ProfileSelectView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSelectView()
            .environmentObject(AuthViewModel(user: CustomDataSet.shared.user()))
    }
}
