import SwiftUI

// MARK: - ScrollBehindScreen
//
// Scaffold for screens whose content scrolls *behind* a fixed header (Settings,
// PrayerSetup). The header is overlaid on top of a ScrollView; the content is
// inset by the measured header height so it starts just below it, then slides up
// and fades out behind a scrim that matches the screen's top background colour.
//
// The screen sets its own full-screen background; this view only owns the scroll
// content + the pinned header + the fade.

struct ScrollBehindScreen<Header: View, Content: View>: View {
    /// The screen's TOP background colour — the header fades content into this.
    var scrim: Color
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    @State private var headerHeight: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            content()
                .padding(.top, headerHeight)
        }
        .overlay(alignment: .top) {
            header()
                .background {
                    // Fade-to-background scrim. Opaque through the header text,
                    // dissolving at the bottom edge so content disappears softly
                    // rather than clipping on a hard line. Extends up under the
                    // status bar so scrolled content is covered there too.
                    LinearGradient(
                        stops: [
                            .init(color: scrim,           location: 0.0),
                            .init(color: scrim,           location: 0.78),
                            .init(color: scrim.opacity(0), location: 1.0),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                }
                .background(
                    GeometryReader { g in
                        Color.clear
                            .onAppear { headerHeight = g.size.height }
                            .onChange(of: g.size.height) { _, h in headerHeight = h }
                    }
                )
        }
    }
}
