import SwiftUI

struct LetterGroup: View {
    @Binding var letters: [Letter]
    var onRearrangeLetters: ([Letter]) -> Void
    
    @State var boxSize = CGSize.zero
    @State var startCellIndex: Int? = nil
    @State var blankCellIndex: Int? = nil
    @State var pointerIndex: Float? = nil
    @State var dragOffset = CGPoint.zero
    @State var draggedLetter: Letter? = nil
    @State var startPointerPosition = CGPoint.zero
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let letterSize = min(80, (geometry.size.width - 32) / CGFloat(max(letters.count, 1)))
                
                if let draggedLetter {
                    BigLetter(letter: draggedLetter,
                             backgroundColor: viewModel.letterColor,
                             size: letterSize)
                        .offset(x: dragOffset.x + startPointerPosition.x - boxSize.width / 2,
                               y: dragOffset.y)
                }
                
                VStack {
                    HStack(spacing: 2) {
                        if letters.count > 0 {
                            ForEach(Array(self.letters.enumerated()), id: \.offset) { pos, letter in
                                BigLetter(letter: letter,
                                         backgroundColor: viewModel.letterColor,
                                         size: letterSize)
                            }
                        } else {
                            BigLetter(letter: Letter(),
                                     backgroundColor: viewModel.letterColor,
                                     size: letterSize)
                        }
                    }
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    boxSize = proxy.size
                                }
                                .onChange(of: proxy.size) { oldSize, newSize in
                                    boxSize = newSize
                                }
                        }
                    )
                    .gesture(DragGesture()
                        .onChanged { drag in
                            guard letters.count > 0 else { return }
                            
                            let percentage = drag.location.x / boxSize.width
                            var index = percentage * CGFloat(letters.count)
                            startPointerPosition = drag.startLocation
                            
                            if index < 0 {
                                index = 0
                            } else if index > CGFloat(letters.count - 1) {
                                index = CGFloat(letters.count - 1)
                            }
                            
                            if draggedLetter == nil {
                                blankCellIndex = Int(index)
                                draggedLetter = letters[blankCellIndex!]
                                letters[blankCellIndex!] = Letter(character: "#", point: 0)
                            }
                            
                            if startCellIndex == nil {
                                startCellIndex = Int(index)
                            }
                            
                            if blankCellIndex != Int(index) {
                                letters[blankCellIndex!] = letters[Int(index)]
                                letters[Int(index)] = Letter(character: "#", point: 0)
                                blankCellIndex = Int(index)
                            }
                            
                            pointerIndex = Float(index)
                            
                            dragOffset = CGPoint(x: drag.location.x - drag.startLocation.x,
                                               y: drag.location.y - drag.startLocation.y)
                        }
                        .onEnded { _ in
                            guard letters.count > 0, blankCellIndex != nil else {
                                draggedLetter = nil
                                pointerIndex = nil
                                startCellIndex = nil
                                blankCellIndex = nil
                                startPointerPosition = CGPoint.zero
                                dragOffset = CGPoint.zero
                                return
                            }
                            
                            letters[blankCellIndex!] = draggedLetter!
                            draggedLetter = nil
                            pointerIndex = nil
                            startCellIndex = nil
                            blankCellIndex = nil
                            startPointerPosition = CGPoint.zero
                            dragOffset = CGPoint.zero
                            
                            self.onRearrangeLetters(letters)
                        }
                    )
                }
            }
        }
    }
}

struct BigLetter: View {
    private let ch: String
    private let pt: Int
    let size: CGFloat
    let backgroundColor: Color
    
    init(letter: Letter, backgroundColor: Color, size: CGFloat = 44) {
        self.ch = letter.text
        self.pt = letter.point
        self.size = size
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(self.ch)
                .font(Font.system(size: 0.8 * self.size, weight: .bold))
                .frame(width: self.size, height: self.size)
            
            if pt > 0 && ch != "#" {
                Text("\(pt)")
                    .font(.system(size: self.size * 0.25))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .offset(x: -4, y: -4)
            }
        }
        .frame(width: self.size, height: self.size)
        .background(self.ch == "#" ? Color.clear : backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.black, lineWidth: 2)
        )
    }
}
