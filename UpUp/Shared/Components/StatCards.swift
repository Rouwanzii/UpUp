import SwiftUI

// MARK: - Session Stat Card

struct SessionStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Padding.small)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.large)
    }
}

// MARK: - Stat Summary Card

struct StatSummaryCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Padding.large)
        .cardStyle()
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .padding(.horizontal, DesignTokens.Padding.small)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignTokens.CornerRadius.small)
    }
}

// MARK: - Completion Stat Card

struct CompletionStatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.xxSmall) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.large)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding()
    }
}
