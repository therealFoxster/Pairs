//
//  ViewController.swift
//  Pairs
//
//  Created by Huy Bui on 2022-12-20.
//

import UIKit

class ViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    private let cardText = "Tap to Reveal"
    
    private let spacing: CGFloat = 14
    private let rows = 4,
                cols = 4
    
    private let colors: [UIColor] = [.blue, .brown, .cyan, .green, .magenta, .orange, .purple, .red, .yellow].shuffled()
    private var colorMatrix: [[UIColor]]!
    private let inactiveColor = UIColor.darkGray
    
    private var previousCard: Card? = nil,
                cards: [Card] = []
    private var correctCards = 0 {
        didSet {
            if correctCards >= rows * cols {
                // Game over.
                gameOver()
            }
        }
    }
    
    private var isTransitioning = false
    
    private var totalGuesses = 0
    private var timer: Timer?,
                secondsElapsed: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = spacing
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
            // Screen width subtracting left & right spacing.
            container.widthAnchor.constraint(equalToConstant: getScreenDimensions().width - spacing * 2),
            // Screen height subtracting top & bottom spacing.
            container.heightAnchor.constraint(equalToConstant: getScreenDimensions().height - spacing * 2),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        for row in 0..<rows {
            let rowOfCards = UIStackView()
            rowOfCards.axis = .horizontal
            rowOfCards.spacing = spacing
            rowOfCards.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(rowOfCards)
            
            NSLayoutConstraint.activate([
                // Spacing count = d - 1.
                // (Height - total spacing) / d.
                rowOfCards.heightAnchor.constraint(equalToConstant: (getScreenDimensions().height - (CGFloat(rows) - 1) * spacing) / CGFloat(rows))
            ])
            
            for col in 0..<cols {
                let card = Card(row: row, col: col)
                card.backgroundColor = inactiveColor
                card.layer.cornerRadius = spacing
//                card.setTitle("(\(row), \(col))", for: .normal)
                
                card.titleLabel?.lineBreakMode = .byWordWrapping
                card.titleLabel?.textAlignment = .center
                card.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                card.setTitle("(\(card.row!), \(card.col!))\n\(cardText)", for: .normal)
                
                card.addTarget(self, action: #selector(didSelectCard(_:)), for: .touchUpInside)
                cards.append(card)
                rowOfCards.addArrangedSubview(card)
                
                NSLayoutConstraint.activate([
                    card.widthAnchor.constraint(equalToConstant: (getScreenDimensions().width - (CGFloat(cols) - 1 + 2) * spacing) / CGFloat(cols)), // + 2 for left & right spacings.
                ])
            }
        }
        
        start()
    }
    
    @objc func didSelectCard(_ card: Card) {
        guard !isTransitioning else { return }
        guard card != previousCard else { return } // Same card selected twice.
        
        let currentColor = colorMatrix[card.row][card.col]
        animate {
            card.backgroundColor = currentColor
            card.transform3D = CATransform3DRotate(card.transform3D, CGFloat.pi, 1, 0, 0)
        }
        card.setTitle("", for: .normal)
        
        if let previousColor = previousCard?.backgroundColor {
            // Second card.
            if currentColor == previousColor {
                // Match.
                card.transform3D = CATransform3DRotate(card.transform3D, CGFloat.pi, 1, 0, 0)
                card.isUserInteractionEnabled = false
                
                previousCard?.transform3D = CATransform3DRotate(self.previousCard!.transform3D, CGFloat.pi, 1, 0, 0)
                previousCard?.isUserInteractionEnabled = false
                
                previousCard = nil
                correctCards += 2
            } else {
                // Mismatch.
                isTransitioning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.animate {
                        card.backgroundColor = self.inactiveColor
                        card.transform3D = CATransform3DRotate(card.transform3D, CGFloat.pi, 1, 0, 0)
                        self.previousCard?.backgroundColor = self.inactiveColor
                        self.previousCard?.transform3D = CATransform3DRotate(self.previousCard!.transform3D, CGFloat.pi, 1, 0, 0)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            card.setTitle("(\(card.row!), \(card.col!))\n\(self.cardText)", for: .normal)
                            self.previousCard?.setTitle("(\(self.previousCard!.row!), \(self.previousCard!.col!))\n\(self.cardText)", for: .normal)
                            self.previousCard = nil
                            self.isTransitioning = false
                        }
                    }
                }
            }
            totalGuesses += 1
        } else {
            // First card.
            previousCard = card
        }
    }
    
    func start() {
        correctCards = 0
        totalGuesses = 0
        
        for card in cards {
            card.backgroundColor = inactiveColor
            card.isUserInteractionEnabled = true
            card.setTitle("(\(card.row!), \(card.col!))\n\(cardText)", for: .normal)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.secondsElapsed += 1
        }
        
        generateColorMatrix()
    }
    
    func gameOver() {
        timer?.invalidate()
        
        let minutesElapsed: Int = secondsElapsed / 60,
            accuracy = Int(CGFloat(rows * cols / 2) / CGFloat(totalGuesses) * 100)
        let timeElapsedString = "Time elapsed: \(minutesElapsed > 0 ? "\(minutesElapsed)m " : "")\(secondsElapsed % 60)s",
            totalGuessesString = "Total guesses: \(totalGuesses)",
            accuracyString = "Accuracy: \(accuracy)%"
        
        let alert = UIAlertController(title: "Game Over", message: "\(timeElapsedString)\n\(totalGuessesString)\n\(accuracyString)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: .default) { [weak self] _ in
            self?.start()
        })
        present(alert, animated: true)
    }
    
    func animate(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: animations)
    }
    
    func generateColorMatrix() {
        colorMatrix = [[UIColor]](repeating: [UIColor](repeating: .black, count: rows), count: cols)
        
        let maxColors = rows * cols / 2
        assert(maxColors < colors.count,
               "Not enough possible colors (\(maxColors) required, \(colors.count) available).")
        
        // Keeping track of color occurences to ensure that each color only appear twice.
        var colorOccurences = [Int](repeating: 0, count: maxColors)
        
        for row in 0..<rows {
            for col in 0..<cols {
                // Set color in color matrix.
                var i = Int.random(in: 0..<maxColors)
                // If color already used twice, generate index for another color.
                while colorOccurences[i] >= 2 {
                    i = Int.random(in: 0..<maxColors)
                }
                colorOccurences[i] += 1
                colorMatrix[row][col] = colors[i]
            }
        }
    }
    
    func getScreenDimensions() -> CGSize {
        var width = UIScreen.main.bounds.width,
            height = UIScreen.main.bounds.height
        // Convert portrait dimensions to landscape.
        if height > width {
            height = width
            width = UIScreen.main.bounds.height
        }
        return CGSize(width: width, height: height)
    }

}

