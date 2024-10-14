import Foundation

struct TutorialScreen {
    let title: String
    let content: String
    let bulletPoints: [String]
    let proTip: String?
}

struct TutorialContent {
    static let screens: [TutorialScreen] = [
        TutorialScreen(
            title: "Why AlphaFlow?",
            content: "Welcome to AlphaFlow, your path to peak masculinity. Our unique combination of exercises is designed to enhance your physical and mental strength, giving you the edge in all areas of life.",
            bulletPoints: [
                "Improved sexual health and performance",
                "Enhanced stress resilience and focus",
                "Better overall physical and mental well-being"
            ],
            proTip: "AlphaFlow integrates three powerful practices: Kegel exercises, box breathing, and meditation. Together, they form a comprehensive approach to male health that you won't find anywhere else."
        ),
        TutorialScreen(
            title: "Kegel Exercises",
            content: "Kegel exercises strengthen your pelvic floor muscles – a crucial but often neglected part of male fitness.",
            bulletPoints: [
                "Enhance sexual function and performance",
                "Improve bladder control",
                "Strengthen your core for better overall fitness"
            ],
            proTip: "Practice Kegels discreetly anytime, anywhere. No one will know you're doing them!"
        ),
        TutorialScreen(
            title: "Box Breathing",
            content: "Box breathing is a powerful technique used by elite athletes and Navy SEALs to maintain calm and focus under pressure.",
            bulletPoints: [
                "Instantly reduce stress and anxiety",
                "Improve focus and decision-making",
                "Enhance sleep quality"
            ],
            proTip: "Use box breathing before important meetings, workouts, or whenever you need to perform at your best."
        ),
        TutorialScreen(
            title: "Meditation",
            content: "Meditation is mental training that sharpens your mind and builds emotional resilience. It's not just for monks – it's for warriors who want to conquer their inner battlefield.",
            bulletPoints: [
                "Reduce stress and anxiety",
                "Improve focus and productivity",
                "Enhance self-awareness and emotional control"
            ],
            proTip: "Consistency is key. Even 5 minutes daily can make a significant impact."
        ),
        TutorialScreen(
            title: "You're Ready to Start!",
            content: "Congratulations, you're now equipped with the AlphaFlow toolkit for male excellence!",
            bulletPoints: [
                "Kegel exercises for pelvic strength",
                "Box breathing for stress control",
                "Meditation for mental mastery"
            ],
            proTip: "Remember, true alphas commit to daily practice. Your journey to peak performance starts now."
        )
    ]
}
