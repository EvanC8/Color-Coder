//
//  ColorStatView.swift
//  ColorCoder
//
//  Created by Evan Cedeno on 12/30/24.
//

import SwiftUI
import CoreML

struct ColorStatView: View {
    
    let statColor: UIColor
    
    @State var title: String = "Color"
    @State var titleProbability: String = "NA%"
    
    @State var footer: String = "NA"
    
    var body: some View {
            ZStack {
                HStack() {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(uiColor: statColor))
                        .shadow(color: Color.gray.opacity(0.5), radius: 0.5)
                        .aspectRatio(1.0, contentMode: .fit)
                    VStack(spacing: 0) {
                        HStack(spacing: 20) {
                            Text(title)
                                .font(.system(size: 40, weight: .bold))
//                                        .minimumScaleFactor(0.25)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("PROBABILITY")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 10, weight: .regular))
                                Text(titleProbability)
                                    .font(.system(size: 20, weight: .heavy))
                            }
                        }
//                                Spacer()
                        HStack {
                            Text(footer)
                                .foregroundStyle(.gray)
                                .font(.system(size: 15, weight: .regular))
                            Spacer()
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.trailing, 10)
                }
                .padding(5)
            }
            .frame(height: 80)
            .background(Color.white.cornerRadius(20))
            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            .onAppear {
                getPrediction()
            }
            .onChange(of: statColor) { oldValue, newValue in
                getPrediction()
            }
        
    }
    
    func getPrediction() {
        do {
            let config = MLModelConfiguration()
            let model = try! ColorCoderTabular2(configuration: config)
            
            let rgba = statColor.rgba
            
            print(rgba)
            
            let prediction = try model.prediction(R: Int64(rgba.red * 255), G: Int64(rgba.green * 255), B: Int64(rgba.blue * 255))
            print(prediction.Label)
            print(prediction.LabelProbability)
            
            let sortedProbs = prediction.LabelProbability.sorted(by: { $0.value > $1.value })
            
            title = sortedProbs[0].key
            titleProbability = probabilityString(sortedProbs[0].value)
            
            footer = probabilityString(sortedProbs[1].value) + " " + sortedProbs[1].key + ", " + probabilityString(sortedProbs[2].value) + " " + sortedProbs[2].key
            
            
        } catch {
            print("Error loading ML model: \(error)")
        }
    }
    
    func probabilityString(_ probability: Double) -> String {
        let percentage = Int(probability * 100)
        
        if percentage == 0 {
            return "<0%"
        }
        
        return "\(percentage)%"
    }
}

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}
