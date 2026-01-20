import SwiftUI

struct SpiderChartView: View {
    let profile: UserProfile
    @State private var editableValues: [String: Double] = [:]
    @State private var isEditing = false
    @State private var showingTooltip: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Chart visualization
            ZStack {
                // Background grid
                SpiderChartBackground()
                
                // Data polygon
                SpiderChartPolygon(values: isEditing ? editableValues : profile.spiderChartValues)
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.blue.opacity(0.2))
                
                // Dimension labels and points
                ForEach(SpiderDimension.allCases, id: \.rawValue) { dimension in
                    let angle = angleForDimension(dimension)
                    let value = (isEditing ? editableValues : profile.spiderChartValues)[dimension.rawValue] ?? 50.0
                    
                    // Label
                    Text(dimension.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .position(
                            x: 150 + cos(angle) * 120,
                            y: 150 + sin(angle) * 120
                        )
                        .onTapGesture {
                            showingTooltip = showingTooltip == dimension.rawValue ? nil : dimension.rawValue
                        }
                    
                    // Data point
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .position(
                            x: 150 + cos(angle) * (value / 100.0 * 100),
                            y: 150 + sin(angle) * (value / 100.0 * 100)
                        )
                }
            }
            .frame(width: 300, height: 300)
            
            // Tooltip
            if let tooltipDimension = showingTooltip,
               let dimension = SpiderDimension.allCases.first(where: { $0.rawValue == tooltipDimension }) {
                VStack(spacing: 8) {
                    Text(dimension.rawValue)
                        .font(.headline)
                    
                    Text(dimension.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .transition(.opacity)
            }
            
            // Edit/Save button
            HStack {
                if isEditing {
                    Button("Cancel") {
                        editableValues = profile.spiderChartValues
                        isEditing = false
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Save") {
                        profile.spiderChartValues = editableValues
                        isEditing = false
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("Edit Profile") {
                        editableValues = profile.spiderChartValues
                        isEditing = true
                    }
                }
            }
            .padding(.horizontal)
            
            // Sliders (when editing)
            if isEditing {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(SpiderDimension.allCases, id: \.rawValue) { dimension in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(dimension.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(editableValues[dimension.rawValue] ?? 50))")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { editableValues[dimension.rawValue] ?? 50.0 },
                                        set: { editableValues[dimension.rawValue] = $0 }
                                    ),
                                    in: 0...100,
                                    step: 1
                                )
                                .tint(.blue)
                                
                                Text(dimension.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
            }
        }
        .onAppear {
            editableValues = profile.spiderChartValues
        }
    }
    
    private func angleForDimension(_ dimension: SpiderDimension) -> Double {
        let index = SpiderDimension.allCases.firstIndex(of: dimension) ?? 0
        let totalDimensions = SpiderDimension.allCases.count
        return Double(index) * (2 * .pi / Double(totalDimensions)) - .pi / 2 // Start from top
    }
}

struct SpiderChartBackground: View {
    var body: some View {
        ZStack {
            // Concentric circles
            ForEach(1..<6) { ring in
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: CGFloat(ring * 40), height: CGFloat(ring * 40))
            }
            
            // Radial lines
            ForEach(0..<12) { index in
                let angle = Double(index) * (2 * .pi / 12) - .pi / 2
                
                Path { path in
                    path.move(to: CGPoint(x: 150, y: 150))
                    path.addLine(to: CGPoint(
                        x: 150 + cos(angle) * 100,
                        y: 150 + sin(angle) * 100
                    ))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
        }
        .frame(width: 300, height: 300)
    }
}

struct SpiderChartPolygon: Shape {
    let values: [String: Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius: Double = 100
        
        let dimensions = SpiderDimension.allCases
        
        for (index, dimension) in dimensions.enumerated() {
            let angle = Double(index) * (2 * .pi / Double(dimensions.count)) - .pi / 2
            let value = values[dimension.rawValue] ?? 50.0
            let radius = (value / 100.0) * maxRadius
            
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct InteractiveSpiderChartView: View {
    @Binding var values: [String: Double]
    @State private var showingTooltip: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Chart
            ZStack {
                SpiderChartBackground()
                SpiderChartPolygon(values: values)
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.blue.opacity(0.2))
                
                // Interactive dimension labels
                ForEach(SpiderDimension.allCases, id: \.rawValue) { dimension in
                    let angle = angleForDimension(dimension)
                    let value = values[dimension.rawValue] ?? 50.0
                    
                    Text(dimension.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .position(
                            x: 150 + cos(angle) * 120,
                            y: 150 + sin(angle) * 120
                        )
                        .onTapGesture {
                            showingTooltip = showingTooltip == dimension.rawValue ? nil : dimension.rawValue
                        }
                }
            }
            .frame(width: 300, height: 300)
            
            // Tooltip
            if let tooltipDimension = showingTooltip,
               let dimension = SpiderDimension.allCases.first(where: { $0.rawValue == tooltipDimension }) {
                VStack(spacing: 8) {
                    Text(dimension.rawValue)
                        .font(.headline)
                    
                    Text(dimension.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .transition(.opacity)
            }
            
            // Sliders
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(SpiderDimension.allCases, id: \.rawValue) { dimension in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(dimension.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(Int(values[dimension.rawValue] ?? 50))")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { values[dimension.rawValue] ?? 50.0 },
                                    set: { values[dimension.rawValue] = $0 }
                                ),
                                in: 0...100,
                                step: 1
                            )
                            .tint(.blue)
                            
                            Text(dimension.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
        }
    }
    
    private func angleForDimension(_ dimension: SpiderDimension) -> Double {
        let index = SpiderDimension.allCases.firstIndex(of: dimension) ?? 0
        let totalDimensions = SpiderDimension.allCases.count
        return Double(index) * (2 * .pi / Double(totalDimensions)) - .pi / 2
    }
}

#Preview {
    let profile = UserProfile(email: "test@example.com")
    return SpiderChartView(profile: profile)
        .padding()
}