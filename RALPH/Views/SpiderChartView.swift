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
                    
                    // Data point (draggable bead)
                    if isEditing {
                        DraggableBead(
                            dimension: dimension,
                            value: Binding(
                                get: { editableValues[dimension.rawValue] ?? 50.0 },
                                set: { editableValues[dimension.rawValue] = $0 }
                            ),
                            angle: angle,
                            center: CGPoint(x: 150, y: 150)
                        )
                    } else {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(
                                x: 150 + cos(angle) * (value / 100.0 * 100),
                                y: 150 + sin(angle) * (value / 100.0 * 100)
                            )
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
            
            // Instructions when editing
            if isEditing {
                Text("Drag the beads on each axis to adjust your preferences")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
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
                
                // Interactive dimension labels and draggable beads
                ForEach(SpiderDimension.allCases, id: \.rawValue) { dimension in
                    let angle = angleForDimension(dimension)

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

                    // Draggable bead
                    DraggableBead(
                        dimension: dimension,
                        value: Binding(
                            get: { values[dimension.rawValue] ?? 50.0 },
                            set: { values[dimension.rawValue] = $0 }
                        ),
                        angle: angle,
                        center: CGPoint(x: 150, y: 150)
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
            
            // Instructions
            Text("Drag the beads along each axis to adjust your preferences")
                .font(.subheadline)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private func angleForDimension(_ dimension: SpiderDimension) -> Double {
        let index = SpiderDimension.allCases.firstIndex(of: dimension) ?? 0
        let totalDimensions = SpiderDimension.allCases.count
        return Double(index) * (2 * .pi / Double(totalDimensions)) - .pi / 2
    }
}

struct DraggableBead: View {
    let dimension: SpiderDimension
    @Binding var value: Double
    let angle: Double
    let center: CGPoint
    @State private var isDragging = false

    var body: some View {
        let radius = value / 100.0 * 100
        let position = CGPoint(
            x: center.x + CGFloat(cos(angle)) * CGFloat(radius),
            y: center.y + CGFloat(sin(angle)) * CGFloat(radius)
        )

        Circle()
            .fill(isDragging ? Color.blue.opacity(0.8) : Color.blue)
            .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .position(position)
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .onChanged { dragValue in
                        isDragging = true

                        // Calculate distance from center
                        let deltaX = dragValue.location.x - center.x
                        let deltaY = dragValue.location.y - center.y
                        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)

                        // Project onto the axis line
                        let projectedDistance = abs(deltaX * CGFloat(cos(angle)) + deltaY * CGFloat(sin(angle)))

                        // Constrain to valid range (0-100 radius)
                        let clampedDistance = min(max(projectedDistance, 0), 100)

                        // Convert back to value (0-100)
                        let newValue = (clampedDistance / 100.0) * 100.0

                        // Update value with haptic feedback
                        if abs(newValue - value) > 2 {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }

                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false

                        // Snap to nearest 5
                        let snappedValue = round(value / 5) * 5
                        withAnimation(.easeOut(duration: 0.2)) {
                            value = snappedValue
                        }

                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
            )
            .animation(.easeOut(duration: 0.2), value: isDragging)
    }
}

#Preview {
    let profile = UserProfile(email: "test@example.com")
    return SpiderChartView(profile: profile)
        .padding()
}