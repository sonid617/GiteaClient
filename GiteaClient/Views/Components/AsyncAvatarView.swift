import SwiftUI

struct AsyncAvatarView: View {
    let url: String
    let size: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.secondary)
            default:
                Color.secondary.opacity(0.3)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
