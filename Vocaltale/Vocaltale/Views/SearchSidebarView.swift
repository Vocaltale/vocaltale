//
//  SearchSidebarView.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/10/15.
//

import SwiftUI

struct SearchSidebarView: View {
    @Binding var category: SidebarCategory

    @FocusState private var focused: Bool
    @State private var focusable: Bool = false

    @ObservedObject private var libraryRepository = LibraryRepository.instance

    var body: some View {
        TextField("sidebar_search_keyword_placeholder", text: $libraryRepository.keyword)
            .padding(.all, 4.0)
            .textFieldStyle(.roundedBorder)
            .focusable(focusable)
            .focused($focused)
            .onChange(of: focused) { value in
                if value && !libraryRepository.keyword.isEmpty {
                    category = .search
                }
            }
            .onChange(of: libraryRepository.keyword) { value in
                category = .search
                LibraryService.instance.search(for: value)
            }
            .onChange(of: category) { value in
                focused = value == .search
            }
            .onAppear {
                // set initial focused state after it gets rendered
                DispatchQueue.main.async {
                    focusable = true
                    focused = category == .search
                }
            }
    }
}

struct SearchSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchSidebarView(category: Binding.constant(.search))
    }
}
