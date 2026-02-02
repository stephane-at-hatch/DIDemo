//
//  StretchyHeaderView.swift
//  DetailScreen
//
//  Created by Stephane Magne on 2026-02-01.
//

import SwiftUI

struct StretchyHeader<Content: View>: View {
    let height: CGFloat
    let content: Content

    init(height: CGFloat, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY

            content
                .frame(
                    width: geo.size.width,
                    height: minY > 0 ? height + minY : height
                )
                .offset(y: minY > 0 ? -minY : 0)
        }
        .frame(height: height)
    }
}
