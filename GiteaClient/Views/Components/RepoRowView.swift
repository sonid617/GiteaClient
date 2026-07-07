import SwiftUI

struct RepoRowView: View {
    let repo: GiteaRepository

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(repo.owner.login.prefix(2).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(avatarColor(for: repo.owner.login))
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                Text(repo.fullName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                if repo.isPrivate {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(Color.appText2)
                }
            }

            if let desc = repo.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(Color.appText2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 14) {
                if let lang = repo.language {
                    HStack(spacing: 4) {
                        Circle().fill(languageColor(lang)).frame(width: 9, height: 9)
                        Text(lang).font(.system(size: 12)).foregroundColor(Color.appText2)
                    }
                }
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.system(size: 11)).foregroundColor(Color.appText3)
                    Text("\(repo.starsCount)").font(.system(size: 12)).foregroundColor(Color.appText2)
                }
                if repo.forksCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "tuningfork").font(.system(size: 11)).foregroundColor(Color.appText3)
                        Text("\(repo.forksCount)").font(.system(size: 12)).foregroundColor(Color.appText2)
                    }
                }
                if let issues = repo.openIssuesCount, issues > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "circle").font(.system(size: 11)).foregroundColor(Color.appText3)
                        Text("\(issues)").font(.system(size: 12)).foregroundColor(Color.appText2)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
