-- Seed 25 Yoga Workout Templates
-- Various styles: Vinyasa, Hatha, Yin, Restorative, Power
-- Category: mobility, Difficulty: varies

INSERT INTO system_workout_templates (id, name, description, category, difficulty, duration_minutes, exercises, tags, source_file) VALUES

-- Sun Salutation A
('a09a0001-0001-4000-8000-000000000001', 'Sun Salutation A (Surya Namaskar A)', 'Classical Ashtanga sun salutation. Foundation of vinyasa practice. 5-10 rounds to warm up body and focus mind.', 'mobility', 'beginner', 15, '{
  "blocks": [
    {"name": "Sun Salutation A", "sequence": 0, "exercises": [
      {"name": "Mountain Pose (Tadasana)", "notes": "Stand tall, feet together, arms at sides. Inhale."},
      {"name": "Upward Salute (Urdhva Hastasana)", "notes": "Inhale, arms overhead, slight backbend."},
      {"name": "Standing Forward Fold (Uttanasana)", "notes": "Exhale, fold forward, hands to floor."},
      {"name": "Halfway Lift (Ardha Uttanasana)", "notes": "Inhale, flat back, fingertips to shins."},
      {"name": "Chaturanga Dandasana", "notes": "Exhale, step/jump back, lower halfway."},
      {"name": "Upward Facing Dog (Urdhva Mukha Svanasana)", "notes": "Inhale, press up, open chest."},
      {"name": "Downward Facing Dog (Adho Mukha Svanasana)", "notes": "Exhale, lift hips, hold 5 breaths."},
      {"name": "Forward Fold", "notes": "Inhale step/jump forward to fold."},
      {"name": "Upward Salute", "notes": "Inhale, rise up with flat back."},
      {"name": "Mountain Pose", "notes": "Exhale, hands to heart. Repeat 5-10 rounds."}
    ]}
  ]
}', ARRAY['yoga', 'sun-salutation', 'vinyasa', 'ashtanga', 'warmup', 'beginner'], 'sun_salutation_a.md'),

-- Sun Salutation B
('a09a0001-0002-4000-8000-000000000002', 'Sun Salutation B (Surya Namaskar B)', 'Dynamic sun salutation with Chair Pose and Warrior I. More challenging than A. Builds heat and strength.', 'mobility', 'intermediate', 20, '{
  "blocks": [
    {"name": "Sun Salutation B", "sequence": 0, "exercises": [
      {"name": "Mountain Pose (Tadasana)", "notes": "Stand tall, ground through feet."},
      {"name": "Chair Pose (Utkatasana)", "notes": "Inhale, bend knees, arms overhead."},
      {"name": "Standing Forward Fold", "notes": "Exhale, fold forward."},
      {"name": "Halfway Lift", "notes": "Inhale, flat back."},
      {"name": "Chaturanga Dandasana", "notes": "Exhale, step back, lower."},
      {"name": "Upward Facing Dog", "notes": "Inhale, open chest."},
      {"name": "Downward Facing Dog", "notes": "Exhale, lift hips."},
      {"name": "Warrior I - Right (Virabhadrasana I)", "notes": "Inhale, step right foot forward."},
      {"name": "Chaturanga", "notes": "Exhale through vinyasa."},
      {"name": "Upward Dog", "notes": "Inhale."},
      {"name": "Downward Dog", "notes": "Exhale."},
      {"name": "Warrior I - Left", "notes": "Inhale, step left foot forward."},
      {"name": "Vinyasa to Down Dog", "notes": "Flow through, hold 5 breaths."},
      {"name": "Forward Fold to Chair", "notes": "Step forward, rise to Chair."},
      {"name": "Mountain Pose", "notes": "Exhale, stand tall. Repeat 3-5 rounds."}
    ]}
  ]
}', ARRAY['yoga', 'sun-salutation', 'vinyasa', 'ashtanga', 'intermediate', 'strength'], 'sun_salutation_b.md'),

-- Morning Vinyasa Flow
('a09a0002-0001-4000-8000-000000000003', 'Morning Vinyasa Flow', 'Energizing morning practice to awaken body and mind. Sun salutations, standing poses, and gentle backbends.', 'mobility', 'intermediate', 30, '{
  "blocks": [
    {"name": "Centering", "sequence": 0, "exercises": [
      {"name": "Seated Meditation", "duration": "2 min", "notes": "Set intention for practice."},
      {"name": "Cat-Cow", "sets": 1, "reps": "10", "notes": "Warm up spine."}
    ]},
    {"name": "Sun Salutations", "sequence": 1, "exercises": [
      {"name": "Sun Salutation A", "sets": 3, "notes": "Build heat gradually."},
      {"name": "Sun Salutation B", "sets": 2, "notes": "Add Warriors."}
    ]},
    {"name": "Standing Sequence", "sequence": 2, "exercises": [
      {"name": "Warrior II (Virabhadrasana II)", "duration": "5 breaths each side"},
      {"name": "Extended Side Angle (Utthita Parsvakonasana)", "duration": "5 breaths each side"},
      {"name": "Triangle Pose (Trikonasana)", "duration": "5 breaths each side"},
      {"name": "Wide-Legged Forward Fold (Prasarita Padottanasana)", "duration": "5 breaths"}
    ]},
    {"name": "Cool Down", "sequence": 3, "exercises": [
      {"name": "Seated Forward Fold (Paschimottanasana)", "duration": "1 min"},
      {"name": "Supine Twist", "duration": "1 min each side"},
      {"name": "Savasana", "duration": "3 min"}
    ]}
  ]
}', ARRAY['yoga', 'vinyasa', 'morning', 'energizing', 'flow', 'intermediate'], 'morning_vinyasa.md'),

-- Evening Restorative Yoga
('a09a0002-0002-4000-8000-000000000004', 'Evening Restorative Yoga', 'Gentle, passive practice for deep relaxation. Supported poses held 3-5 minutes. Perfect before bed.', 'mobility', 'beginner', 45, '{
  "blocks": [
    {"name": "Grounding", "sequence": 0, "exercises": [
      {"name": "Supported Child Pose", "duration": "5 min", "notes": "Bolster under torso. Breathe deeply."},
      {"name": "Supported Reclined Butterfly (Supta Baddha Konasana)", "duration": "5 min", "notes": "Bolster under spine, blocks under knees."}
    ]},
    {"name": "Hip Opening", "sequence": 1, "exercises": [
      {"name": "Supported Pigeon", "duration": "4 min each side", "notes": "Bolster under hip and chest."},
      {"name": "Supported Frog Pose", "duration": "4 min", "notes": "Bolster under chest."}
    ]},
    {"name": "Spinal Release", "sequence": 2, "exercises": [
      {"name": "Supported Twist", "duration": "3 min each side", "notes": "Bolster between legs."},
      {"name": "Legs Up The Wall (Viparita Karani)", "duration": "5 min", "notes": "Blanket under hips."}
    ]},
    {"name": "Final Rest", "sequence": 3, "exercises": [
      {"name": "Savasana", "duration": "10 min", "notes": "Eye pillow, blanket. Full surrender."}
    ]}
  ]
}', ARRAY['yoga', 'restorative', 'evening', 'relaxation', 'gentle', 'stress-relief'], 'evening_restorative.md'),

-- Power Yoga
('a09a0003-0001-4000-8000-000000000005', 'Power Yoga', 'Athletic, strength-building vinyasa practice. Continuous movement, challenging holds, core engagement throughout.', 'mobility', 'advanced', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Sun Salutation A", "sets": 5, "notes": "Build heat quickly."},
      {"name": "Sun Salutation B", "sets": 3, "notes": "Strong legs."}
    ]},
    {"name": "Standing Power Sequence", "sequence": 1, "exercises": [
      {"name": "Chair Pose Hold", "duration": "1 min", "notes": "Thighs burning."},
      {"name": "Warrior III (Virabhadrasana III)", "duration": "30 sec each side"},
      {"name": "Standing Split", "duration": "30 sec each side"},
      {"name": "Crow Pose (Bakasana)", "duration": "30 sec", "notes": "Arm balance."},
      {"name": "Warrior II Flow", "duration": "10 breaths each side", "notes": "Pulse and hold."}
    ]},
    {"name": "Core Power", "sequence": 2, "exercises": [
      {"name": "Plank Hold", "duration": "1 min"},
      {"name": "Side Plank (Vasisthasana)", "duration": "30 sec each side"},
      {"name": "Boat Pose (Navasana)", "sets": 3, "duration": "30 sec"},
      {"name": "Chaturanga Push-ups", "sets": 1, "reps": "10"}
    ]},
    {"name": "Cool Down", "sequence": 3, "exercises": [
      {"name": "Pigeon Pose", "duration": "2 min each side"},
      {"name": "Seated Forward Fold", "duration": "2 min"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'power', 'strength', 'athletic', 'advanced', 'vinyasa'], 'power_yoga.md'),

-- Yin Yoga - Deep Stretch
('a09a0004-0001-4000-8000-000000000006', 'Yin Yoga - Deep Stretch', 'Passive, long-held poses targeting connective tissue. Hold each pose 3-5 minutes. Meditative and therapeutic.', 'mobility', 'beginner', 60, '{
  "blocks": [
    {"name": "Lower Body", "sequence": 0, "exercises": [
      {"name": "Butterfly Pose (Baddha Konasana)", "duration": "5 min", "notes": "Fold forward, round spine."},
      {"name": "Dragon Pose (Low Lunge)", "duration": "4 min each side", "notes": "Deep hip flexor stretch."},
      {"name": "Sleeping Swan (Pigeon)", "duration": "4 min each side", "notes": "Fold over front leg."},
      {"name": "Square Pose (Fire Log)", "duration": "3 min each side", "notes": "Shin stacking."}
    ]},
    {"name": "Spine", "sequence": 1, "exercises": [
      {"name": "Caterpillar (Seated Forward Fold)", "duration": "5 min", "notes": "Let spine round."},
      {"name": "Sphinx Pose", "duration": "4 min", "notes": "Gentle backbend, forearms down."},
      {"name": "Twisted Roots", "duration": "4 min each side", "notes": "Supine twist, knees bent."}
    ]},
    {"name": "Final Poses", "sequence": 2, "exercises": [
      {"name": "Happy Baby", "duration": "3 min", "notes": "Rock gently side to side."},
      {"name": "Savasana", "duration": "5-10 min", "notes": "Complete stillness."}
    ]}
  ]
}', ARRAY['yoga', 'yin', 'deep-stretch', 'passive', 'meditative', 'connective-tissue'], 'yin_yoga.md'),

-- Yoga for Back Pain
('a09a0005-0001-4000-8000-000000000007', 'Yoga for Back Pain Relief', 'Therapeutic sequence for lower back pain. Gentle stretches, core activation, and spinal mobility.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Gentle Warmup", "sequence": 0, "exercises": [
      {"name": "Constructive Rest", "duration": "2 min", "notes": "Knees bent, feet flat, arms relaxed."},
      {"name": "Pelvic Tilts", "sets": 1, "reps": "10", "notes": "Flatten and arch lower back."},
      {"name": "Knee-to-Chest", "duration": "1 min each side", "notes": "Gentle hip flexor release."}
    ]},
    {"name": "Spinal Mobility", "sequence": 1, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10", "notes": "Slow, fluid movement."},
      {"name": "Thread the Needle", "duration": "1 min each side", "notes": "Thoracic rotation."},
      {"name": "Child Pose", "duration": "2 min", "notes": "Wide knees, arms extended."}
    ]},
    {"name": "Strengthening", "sequence": 2, "exercises": [
      {"name": "Bird Dog", "sets": 2, "reps": "8 each side", "notes": "Core stability."},
      {"name": "Bridge Pose (Setu Bandhasana)", "sets": 3, "duration": "30 sec", "notes": "Glute activation."},
      {"name": "Sphinx Pose", "duration": "1 min", "notes": "Gentle extension."}
    ]},
    {"name": "Release", "sequence": 3, "exercises": [
      {"name": "Supine Figure Four", "duration": "2 min each side", "notes": "Piriformis stretch."},
      {"name": "Supine Twist", "duration": "2 min each side"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'back-pain', 'therapeutic', 'gentle', 'spine', 'beginner'], 'yoga_back_pain.md'),

-- Yoga for Stress Relief
('a09a0005-0002-4000-8000-000000000008', 'Yoga for Stress Relief', 'Calming practice to activate parasympathetic nervous system. Forward folds, gentle twists, breathwork.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Breathwork", "sequence": 0, "exercises": [
      {"name": "Diaphragmatic Breathing", "duration": "3 min", "notes": "Hand on belly, slow deep breaths."},
      {"name": "4-7-8 Breath", "sets": 5, "notes": "Inhale 4, hold 7, exhale 8."}
    ]},
    {"name": "Grounding Poses", "sequence": 1, "exercises": [
      {"name": "Child Pose", "duration": "3 min", "notes": "Forehead to floor, arms back."},
      {"name": "Puppy Pose", "duration": "2 min", "notes": "Heart melts toward floor."},
      {"name": "Seated Forward Fold", "duration": "3 min", "notes": "Let go of effort."}
    ]},
    {"name": "Calming Sequence", "sequence": 2, "exercises": [
      {"name": "Legs Up The Wall", "duration": "5 min", "notes": "Reverse blood flow."},
      {"name": "Reclined Butterfly", "duration": "3 min", "notes": "Open hips, open heart."},
      {"name": "Supine Twist", "duration": "2 min each side", "notes": "Wring out tension."}
    ]},
    {"name": "Final Rest", "sequence": 3, "exercises": [
      {"name": "Savasana with Body Scan", "duration": "5 min", "notes": "Progressive relaxation."}
    ]}
  ]
}', ARRAY['yoga', 'stress-relief', 'calming', 'breathwork', 'relaxation', 'gentle'], 'yoga_stress_relief.md'),

-- Yoga for Better Sleep
('a09a0005-0003-4000-8000-000000000009', 'Yoga for Better Sleep', 'Pre-bedtime practice to prepare body and mind for rest. All poses on the floor, minimal effort required.', 'mobility', 'beginner', 20, '{
  "blocks": [
    {"name": "Settle In", "sequence": 0, "exercises": [
      {"name": "Supported Child Pose", "duration": "3 min", "notes": "Pillow under belly."},
      {"name": "Neck Rolls", "sets": 1, "reps": "5 each direction", "notes": "Release neck tension."}
    ]},
    {"name": "Hip Release", "sequence": 1, "exercises": [
      {"name": "Reclined Pigeon", "duration": "2 min each side", "notes": "Figure-four stretch."},
      {"name": "Happy Baby", "duration": "2 min", "notes": "Rock gently."},
      {"name": "Reclined Butterfly", "duration": "3 min", "notes": "Pillows under knees."}
    ]},
    {"name": "Final Relaxation", "sequence": 2, "exercises": [
      {"name": "Legs Up The Wall", "duration": "5 min", "notes": "Close eyes, breathe."},
      {"name": "Savasana", "duration": "5 min", "notes": "Transition to sleep."}
    ]}
  ]
}', ARRAY['yoga', 'sleep', 'bedtime', 'relaxation', 'gentle', 'evening'], 'yoga_sleep.md'),

-- Yoga for Athletes
('a09a0006-0001-4000-8000-000000000010', 'Yoga for Athletes', 'Recovery-focused practice for athletes. Target tight hips, hamstrings, shoulders. Improve flexibility and prevent injury.', 'mobility', 'intermediate', 40, '{
  "blocks": [
    {"name": "Dynamic Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10"},
      {"name": "Sun Salutation A", "sets": 3, "notes": "Light warm-up."}
    ]},
    {"name": "Hip Openers", "sequence": 1, "exercises": [
      {"name": "Low Lunge (Anjaneyasana)", "duration": "1 min each side", "notes": "Hip flexor stretch."},
      {"name": "Lizard Pose", "duration": "1 min each side", "notes": "Deep hip opener."},
      {"name": "Pigeon Pose", "duration": "2 min each side", "notes": "Glute and piriformis."},
      {"name": "Frog Pose", "duration": "2 min", "notes": "Inner thigh stretch."}
    ]},
    {"name": "Hamstrings & Shoulders", "sequence": 2, "exercises": [
      {"name": "Standing Forward Fold", "duration": "1 min", "notes": "Clasp elbows."},
      {"name": "Wide-Legged Forward Fold", "duration": "1 min"},
      {"name": "Eagle Arms (Garudasana arms)", "duration": "1 min each side", "notes": "Upper back release."},
      {"name": "Cow Face Arms (Gomukhasana arms)", "duration": "1 min each side", "notes": "Shoulder opener."}
    ]},
    {"name": "Cool Down", "sequence": 3, "exercises": [
      {"name": "Supine Twist", "duration": "2 min each side"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'athletes', 'recovery', 'flexibility', 'hips', 'shoulders'], 'yoga_athletes.md'),

-- Beginner's First Yoga Class
('a09a0007-0001-4000-8000-000000000011', 'Beginner Yoga Fundamentals', 'Introduction to basic yoga poses. Learn alignment, breath, and foundational postures. No experience needed.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Introduction", "sequence": 0, "exercises": [
      {"name": "Easy Seated Pose (Sukhasana)", "duration": "2 min", "notes": "Find comfortable seat. Close eyes."},
      {"name": "Breath Awareness", "duration": "2 min", "notes": "Notice natural breath rhythm."}
    ]},
    {"name": "Basic Poses", "sequence": 1, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10", "notes": "Learn to move with breath."},
      {"name": "Downward Facing Dog", "duration": "5 breaths", "notes": "Inverted V shape. Bend knees if needed."},
      {"name": "Mountain Pose", "duration": "1 min", "notes": "Foundation of all standing poses."},
      {"name": "Warrior I", "duration": "5 breaths each side", "notes": "Front knee over ankle."},
      {"name": "Warrior II", "duration": "5 breaths each side", "notes": "Arms parallel to floor."},
      {"name": "Tree Pose (Vrksasana)", "duration": "30 sec each side", "notes": "Balance on one leg."}
    ]},
    {"name": "Floor Poses", "sequence": 2, "exercises": [
      {"name": "Child Pose", "duration": "1 min", "notes": "Rest pose. Return here anytime."},
      {"name": "Cobra Pose (Bhujangasana)", "sets": 2, "duration": "30 sec", "notes": "Gentle backbend."},
      {"name": "Seated Forward Fold", "duration": "1 min", "notes": "Reach for feet or shins."}
    ]},
    {"name": "Closing", "sequence": 3, "exercises": [
      {"name": "Savasana", "duration": "5 min", "notes": "Final relaxation. Let go completely."}
    ]}
  ]
}', ARRAY['yoga', 'beginner', 'fundamentals', 'basics', 'introduction', 'first-class'], 'beginner_yoga.md'),

-- Hip Opening Flow
('a09a0008-0001-4000-8000-000000000012', 'Hip Opening Flow', 'Deep hip opening sequence. Release tension from sitting, improve range of motion, access stored emotions.', 'mobility', 'intermediate', 45, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10"},
      {"name": "Sun Salutation A", "sets": 3},
      {"name": "Goddess Squat (Utkata Konasana)", "duration": "1 min", "notes": "Wide stance, deep bend."}
    ]},
    {"name": "Standing Hip Openers", "sequence": 1, "exercises": [
      {"name": "Warrior II", "duration": "5 breaths each side"},
      {"name": "Extended Side Angle", "duration": "5 breaths each side"},
      {"name": "Triangle Pose", "duration": "5 breaths each side"},
      {"name": "Half Moon (Ardha Chandrasana)", "duration": "5 breaths each side", "notes": "Open hip to sky."}
    ]},
    {"name": "Deep Hip Work", "sequence": 2, "exercises": [
      {"name": "Low Lunge with Twist", "duration": "1 min each side"},
      {"name": "Lizard Pose", "duration": "2 min each side", "notes": "Forearms down if possible."},
      {"name": "Pigeon Pose", "duration": "3 min each side", "notes": "Breathe into tight spots."},
      {"name": "Frog Pose", "duration": "3 min", "notes": "Wide knees, hips sink."},
      {"name": "Fire Log Pose (Agnistambhasana)", "duration": "2 min each side"}
    ]},
    {"name": "Integration", "sequence": 3, "exercises": [
      {"name": "Happy Baby", "duration": "2 min"},
      {"name": "Supine Butterfly", "duration": "2 min"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'hips', 'hip-opening', 'flexibility', 'intermediate', 'deep-stretch'], 'hip_opening_flow.md'),

-- Heart Opening & Backbends
('a09a0008-0002-4000-8000-000000000013', 'Heart Opening & Backbends', 'Chest opening sequence to counteract forward posture. Progressive backbends from gentle to deeper expressions.', 'mobility', 'intermediate', 40, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10"},
      {"name": "Sun Salutation A", "sets": 3},
      {"name": "Sun Salutation B", "sets": 2}
    ]},
    {"name": "Shoulder Prep", "sequence": 1, "exercises": [
      {"name": "Eagle Arms", "duration": "1 min each side"},
      {"name": "Cow Face Arms", "duration": "1 min each side"},
      {"name": "Reverse Prayer", "duration": "1 min"}
    ]},
    {"name": "Backbend Progression", "sequence": 2, "exercises": [
      {"name": "Sphinx Pose", "duration": "1 min", "notes": "Forearms down, gentle arch."},
      {"name": "Cobra Pose", "sets": 3, "duration": "30 sec", "notes": "Hands light, lift with back."},
      {"name": "Upward Facing Dog", "sets": 2, "duration": "30 sec"},
      {"name": "Locust Pose (Salabhasana)", "sets": 2, "duration": "30 sec", "notes": "Arms and legs lift."},
      {"name": "Bow Pose (Dhanurasana)", "sets": 2, "duration": "30 sec", "notes": "Hold ankles, lift."},
      {"name": "Camel Pose (Ustrasana)", "duration": "1 min", "notes": "Hands to heels or blocks."},
      {"name": "Wheel Pose (Urdhva Dhanurasana)", "sets": 3, "duration": "30 sec", "notes": "Optional advanced backbend."}
    ]},
    {"name": "Counter Poses", "sequence": 3, "exercises": [
      {"name": "Child Pose", "duration": "2 min"},
      {"name": "Supine Twist", "duration": "2 min each side"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'backbends', 'heart-opening', 'chest', 'shoulders', 'intermediate'], 'heart_opening.md'),

-- Core & Balance Flow
('a09a0008-0003-4000-8000-000000000014', 'Core & Balance Flow', 'Build core strength and improve balance. Challenging holds, arm balances, and single-leg poses.', 'mobility', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Sun Salutation A", "sets": 3},
      {"name": "Boat Pose (Navasana)", "sets": 2, "duration": "30 sec"}
    ]},
    {"name": "Core Work", "sequence": 1, "exercises": [
      {"name": "Plank Hold", "duration": "1 min"},
      {"name": "Forearm Plank", "duration": "1 min"},
      {"name": "Side Plank", "duration": "30 sec each side"},
      {"name": "Boat to Low Boat", "sets": 10, "notes": "Lower and lift."},
      {"name": "Bicycle Crunches", "sets": 1, "reps": "20", "notes": "Yogi bicycle."}
    ]},
    {"name": "Balance Poses", "sequence": 2, "exercises": [
      {"name": "Tree Pose", "duration": "1 min each side"},
      {"name": "Eagle Pose (Garudasana)", "duration": "30 sec each side"},
      {"name": "Warrior III", "duration": "30 sec each side"},
      {"name": "Half Moon", "duration": "30 sec each side"},
      {"name": "Standing Split", "duration": "30 sec each side"}
    ]},
    {"name": "Arm Balances", "sequence": 3, "exercises": [
      {"name": "Crow Pose", "sets": 3, "duration": "15 sec"},
      {"name": "Side Crow", "sets": 2, "duration": "10 sec each side", "notes": "Optional."}
    ]},
    {"name": "Cool Down", "sequence": 4, "exercises": [
      {"name": "Seated Forward Fold", "duration": "2 min"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'core', 'balance', 'strength', 'arm-balance', 'intermediate'], 'core_balance_flow.md'),

-- Moon Salutation
('a09a0009-0001-4000-8000-000000000015', 'Moon Salutation (Chandra Namaskar)', 'Cooling, feminine counterpart to Sun Salutation. Side-to-side movement, hip openers, calming energy.', 'mobility', 'beginner', 20, '{
  "blocks": [
    {"name": "Moon Salutation", "sequence": 0, "exercises": [
      {"name": "Mountain Pose", "notes": "Stand tall, hands at heart."},
      {"name": "Upward Salute with Side Bend", "notes": "Inhale up, exhale lean right, inhale center, exhale lean left."},
      {"name": "Goddess Squat", "notes": "Wide stance, arms cactus, exhale sink."},
      {"name": "Star Pose", "notes": "Inhale, straighten legs, arms wide."},
      {"name": "Triangle Pose Right", "notes": "Exhale, reach right."},
      {"name": "Pyramid Pose Right", "notes": "Square hips, fold over right leg."},
      {"name": "Low Lunge Right", "notes": "Drop back knee."},
      {"name": "Low Side Lunge (Skandasana) Right", "notes": "Shift weight, straighten left leg."},
      {"name": "Garland Pose (Malasana)", "notes": "Center, deep squat."},
      {"name": "Low Side Lunge Left", "notes": "Shift to left."},
      {"name": "Low Lunge Left", "notes": "Rise, back knee down."},
      {"name": "Pyramid Pose Left", "notes": "Step back, fold."},
      {"name": "Triangle Pose Left", "notes": "Open chest."},
      {"name": "Star Pose", "notes": "Rise up."},
      {"name": "Goddess Squat", "notes": "Sink down."},
      {"name": "Mountain Pose", "notes": "Return to start. Repeat 3-5 rounds."}
    ]}
  ]
}', ARRAY['yoga', 'moon-salutation', 'chandra', 'cooling', 'feminine', 'evening'], 'moon_salutation.md'),

-- Twist & Detox Flow
('a09a0010-0001-4000-8000-000000000016', 'Twist & Detox Flow', 'Revitalizing sequence focused on twists. Stimulate digestion, wring out tension, energize the spine.', 'mobility', 'intermediate', 35, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10"},
      {"name": "Sun Salutation A", "sets": 3}
    ]},
    {"name": "Standing Twists", "sequence": 1, "exercises": [
      {"name": "Revolved Chair (Parivrtta Utkatasana)", "duration": "5 breaths each side"},
      {"name": "Revolved Crescent Lunge", "duration": "5 breaths each side"},
      {"name": "Revolved Triangle (Parivrtta Trikonasana)", "duration": "5 breaths each side"},
      {"name": "Revolved Half Moon", "duration": "5 breaths each side"}
    ]},
    {"name": "Seated Twists", "sequence": 2, "exercises": [
      {"name": "Half Lord of the Fishes (Ardha Matsyendrasana)", "duration": "1 min each side", "notes": "Tall spine, deep rotation."},
      {"name": "Revolved Head-to-Knee (Parivrtta Janu Sirsasana)", "duration": "1 min each side"},
      {"name": "Supine Twist", "duration": "2 min each side", "notes": "Let gravity do the work."}
    ]},
    {"name": "Cool Down", "sequence": 3, "exercises": [
      {"name": "Happy Baby", "duration": "1 min"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'twists', 'detox', 'digestion', 'spine', 'intermediate'], 'twist_detox.md'),

-- Chair Yoga (Office/Seated)
('a09a0011-0001-4000-8000-000000000017', 'Chair Yoga for Office Workers', 'Yoga you can do at your desk. Release tension from sitting, no mat needed. Perfect for work breaks.', 'mobility', 'beginner', 15, '{
  "blocks": [
    {"name": "Seated Stretches", "sequence": 0, "exercises": [
      {"name": "Seated Cat-Cow", "sets": 1, "reps": "10", "notes": "Hands on knees, arch and round."},
      {"name": "Neck Rolls", "sets": 1, "reps": "5 each direction"},
      {"name": "Shoulder Rolls", "sets": 1, "reps": "10"},
      {"name": "Seated Side Stretch", "duration": "30 sec each side", "notes": "One arm overhead, lean."},
      {"name": "Seated Twist", "duration": "30 sec each side", "notes": "Hand to opposite knee."}
    ]},
    {"name": "Upper Body", "sequence": 1, "exercises": [
      {"name": "Eagle Arms", "duration": "30 sec each side"},
      {"name": "Cow Face Arms", "duration": "30 sec each side"},
      {"name": "Wrist Circles", "sets": 1, "reps": "10 each direction"},
      {"name": "Seated Forward Fold", "duration": "1 min", "notes": "Fold over thighs."}
    ]},
    {"name": "Legs", "sequence": 2, "exercises": [
      {"name": "Seated Figure Four", "duration": "1 min each side", "notes": "Ankle on opposite knee."},
      {"name": "Seated Hamstring Stretch", "duration": "30 sec each side", "notes": "Extend one leg."},
      {"name": "Ankle Circles", "sets": 1, "reps": "10 each direction"}
    ]},
    {"name": "Closing", "sequence": 3, "exercises": [
      {"name": "Breath Awareness", "duration": "1 min", "notes": "Close eyes, breathe deeply."}
    ]}
  ]
}', ARRAY['yoga', 'chair', 'office', 'desk', 'seated', 'work-break'], 'chair_yoga.md'),

-- Yoga for Runners
('a09a0012-0001-4000-8000-000000000018', 'Yoga for Runners', 'Target runner-specific tightness: hips, hamstrings, IT band, calves. Pre or post-run practice.', 'mobility', 'beginner', 30, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Cat-Cow", "sets": 1, "reps": "10"},
      {"name": "Downward Facing Dog", "duration": "1 min", "notes": "Pedal feet."}
    ]},
    {"name": "Hips & Quads", "sequence": 1, "exercises": [
      {"name": "Low Lunge", "duration": "1 min each side", "notes": "Sink hip flexors."},
      {"name": "Half Split (Ardha Hanumanasana)", "duration": "1 min each side", "notes": "Hamstring stretch."},
      {"name": "Lizard Pose", "duration": "1 min each side"},
      {"name": "Quad Stretch in Lunge", "duration": "1 min each side", "notes": "Grab back foot."}
    ]},
    {"name": "IT Band & Outer Hip", "sequence": 2, "exercises": [
      {"name": "Figure Four Stretch", "duration": "2 min each side"},
      {"name": "Reclined Twist", "duration": "1 min each side", "notes": "IT band release."},
      {"name": "Thread the Needle", "duration": "1 min each side"}
    ]},
    {"name": "Calves & Feet", "sequence": 3, "exercises": [
      {"name": "Downward Dog with Calf Stretch", "duration": "1 min", "notes": "One heel at a time."},
      {"name": "Toe Stretch", "duration": "1 min", "notes": "Sit on heels, toes tucked."}
    ]},
    {"name": "Cool Down", "sequence": 4, "exercises": [
      {"name": "Legs Up The Wall", "duration": "3 min"},
      {"name": "Savasana", "duration": "2 min"}
    ]}
  ]
}', ARRAY['yoga', 'runners', 'running', 'hips', 'hamstrings', 'recovery'], 'yoga_runners.md'),

-- Ashtanga Primary Series (Modified)
('a09a0013-0001-4000-8000-000000000019', 'Ashtanga Primary Series (Modified)', 'Abbreviated version of the traditional Ashtanga Primary Series. Standing poses and select seated poses.', 'mobility', 'advanced', 60, '{
  "blocks": [
    {"name": "Sun Salutations", "sequence": 0, "exercises": [
      {"name": "Sun Salutation A", "sets": 5},
      {"name": "Sun Salutation B", "sets": 5}
    ]},
    {"name": "Standing Sequence", "sequence": 1, "exercises": [
      {"name": "Padangusthasana (Big Toe Pose)", "duration": "5 breaths"},
      {"name": "Padahastasana (Hand Under Foot)", "duration": "5 breaths"},
      {"name": "Trikonasana (Triangle)", "duration": "5 breaths each side"},
      {"name": "Parivrtta Trikonasana (Revolved Triangle)", "duration": "5 breaths each side"},
      {"name": "Utthita Parsvakonasana (Extended Side Angle)", "duration": "5 breaths each side"},
      {"name": "Prasarita Padottanasana A-D", "duration": "5 breaths each"},
      {"name": "Parsvottanasana (Pyramid)", "duration": "5 breaths each side"},
      {"name": "Utthita Hasta Padangusthasana", "duration": "5 breaths each side", "notes": "Standing leg balance."},
      {"name": "Virabhadrasana I & II", "duration": "5 breaths each"}
    ]},
    {"name": "Seated Sequence (Selected)", "sequence": 2, "exercises": [
      {"name": "Dandasana (Staff Pose)", "duration": "5 breaths"},
      {"name": "Paschimottanasana (Seated Forward Fold)", "duration": "5 breaths"},
      {"name": "Janu Sirsasana A (Head-to-Knee)", "duration": "5 breaths each side"},
      {"name": "Marichyasana A & C", "duration": "5 breaths each side"},
      {"name": "Navasana (Boat Pose)", "sets": 5, "duration": "5 breaths"}
    ]},
    {"name": "Closing", "sequence": 3, "exercises": [
      {"name": "Shoulderstand (Sarvangasana)", "duration": "10 breaths"},
      {"name": "Plow Pose (Halasana)", "duration": "5 breaths"},
      {"name": "Fish Pose (Matsyasana)", "duration": "5 breaths"},
      {"name": "Headstand (Sirsasana)", "duration": "10 breaths", "notes": "Optional."},
      {"name": "Padmasana (Lotus) or Easy Seat", "duration": "10 breaths"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'ashtanga', 'primary-series', 'traditional', 'advanced', 'mysore'], 'ashtanga_primary.md'),

-- Slow Flow / Gentle Yoga
('a09a0014-0001-4000-8000-000000000020', 'Slow Flow Gentle Yoga', 'Mindful, slower-paced vinyasa. Longer holds, accessible poses, emphasis on breath over movement.', 'mobility', 'beginner', 45, '{
  "blocks": [
    {"name": "Centering", "sequence": 0, "exercises": [
      {"name": "Seated Meditation", "duration": "3 min"},
      {"name": "Gentle Neck Stretches", "duration": "2 min"},
      {"name": "Cat-Cow", "sets": 1, "reps": "10", "notes": "Extra slow."}
    ]},
    {"name": "Gentle Flow", "sequence": 1, "exercises": [
      {"name": "Child Pose to Tabletop", "sets": 5, "notes": "Flow with breath."},
      {"name": "Downward Dog to Plank", "sets": 5, "notes": "Gentle transitions."},
      {"name": "Sun Salutation A (Modified)", "sets": 2, "notes": "Cobra instead of Up Dog."}
    ]},
    {"name": "Standing Poses", "sequence": 2, "exercises": [
      {"name": "Mountain Pose", "duration": "1 min", "notes": "Really feel it."},
      {"name": "Warrior I", "duration": "8 breaths each side"},
      {"name": "Warrior II", "duration": "8 breaths each side"},
      {"name": "Triangle Pose", "duration": "8 breaths each side"},
      {"name": "Wide-Legged Forward Fold", "duration": "1 min"}
    ]},
    {"name": "Floor Sequence", "sequence": 3, "exercises": [
      {"name": "Seated Forward Fold", "duration": "2 min"},
      {"name": "Butterfly Pose", "duration": "2 min"},
      {"name": "Supine Twist", "duration": "2 min each side"},
      {"name": "Happy Baby", "duration": "2 min"}
    ]},
    {"name": "Relaxation", "sequence": 4, "exercises": [
      {"name": "Savasana", "duration": "7 min"}
    ]}
  ]
}', ARRAY['yoga', 'slow-flow', 'gentle', 'mindful', 'beginner', 'accessible'], 'slow_flow.md'),

-- Advanced Arm Balance & Inversions
('a09a0015-0001-4000-8000-000000000021', 'Advanced Arm Balances & Inversions', 'Challenging practice for experienced yogis. Arm balances, inversions, and advanced transitions.', 'mobility', 'advanced', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Sun Salutation A", "sets": 5},
      {"name": "Sun Salutation B", "sets": 5},
      {"name": "Core Work", "duration": "5 min", "notes": "Plank, boat, bicycles."}
    ]},
    {"name": "Arm Balance Prep", "sequence": 1, "exercises": [
      {"name": "Wrist Warm-up", "duration": "2 min"},
      {"name": "Dolphin Pose", "duration": "1 min"},
      {"name": "Forearm Plank", "duration": "1 min"}
    ]},
    {"name": "Arm Balances", "sequence": 2, "exercises": [
      {"name": "Crow Pose (Bakasana)", "sets": 3, "duration": "30 sec"},
      {"name": "Side Crow (Parsva Bakasana)", "sets": 3, "duration": "20 sec each side"},
      {"name": "Flying Pigeon (Eka Pada Galavasana)", "sets": 2, "duration": "15 sec each side"},
      {"name": "Eight Angle Pose (Astavakrasana)", "sets": 2, "duration": "15 sec each side"},
      {"name": "Firefly Pose (Tittibhasana)", "sets": 2, "duration": "15 sec"}
    ]},
    {"name": "Inversions", "sequence": 3, "exercises": [
      {"name": "Forearm Stand (Pincha Mayurasana)", "sets": 3, "duration": "30 sec", "notes": "At wall if needed."},
      {"name": "Headstand (Sirsasana)", "duration": "2 min"},
      {"name": "Handstand (Adho Mukha Vrksasana)", "sets": 5, "duration": "15 sec", "notes": "Kick up or press."},
      {"name": "Scorpion Pose", "sets": 2, "duration": "15 sec", "notes": "Optional advanced."}
    ]},
    {"name": "Cool Down", "sequence": 4, "exercises": [
      {"name": "Child Pose", "duration": "2 min"},
      {"name": "Supine Twist", "duration": "2 min each side"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'arm-balance', 'inversions', 'advanced', 'handstand', 'headstand'], 'advanced_arm_balance.md'),

-- Prenatal Yoga
('a09a0016-0001-4000-8000-000000000022', 'Prenatal Yoga', 'Safe, supportive practice for pregnancy. Open hips, relieve back pain, connect with baby. Avoid twists and deep backbends.', 'mobility', 'beginner', 40, '{
  "blocks": [
    {"name": "Centering", "sequence": 0, "exercises": [
      {"name": "Seated Meditation", "duration": "3 min", "notes": "Hand on belly, connect with baby."},
      {"name": "Cat-Cow", "sets": 1, "reps": "10", "notes": "Relief for lower back."}
    ]},
    {"name": "Standing Poses", "sequence": 1, "exercises": [
      {"name": "Mountain Pose", "duration": "1 min"},
      {"name": "Warrior II (Wide Stance)", "duration": "5 breaths each side", "notes": "Strong legs."},
      {"name": "Extended Side Angle", "duration": "5 breaths each side"},
      {"name": "Wide-Legged Forward Fold", "duration": "1 min", "notes": "Hands on blocks."},
      {"name": "Goddess Squat", "duration": "1 min", "notes": "Open hips for birth."}
    ]},
    {"name": "Hip Openers", "sequence": 2, "exercises": [
      {"name": "Low Lunge (Modified)", "duration": "1 min each side"},
      {"name": "Pigeon Pose (Supported)", "duration": "2 min each side", "notes": "Bolster under hip."},
      {"name": "Butterfly Pose", "duration": "2 min", "notes": "Props under knees."}
    ]},
    {"name": "Relaxation", "sequence": 3, "exercises": [
      {"name": "Side-Lying Savasana", "duration": "5 min", "notes": "Left side, pillow between knees."}
    ]}
  ]
}', ARRAY['yoga', 'prenatal', 'pregnancy', 'gentle', 'hips', 'safe'], 'prenatal_yoga.md'),

-- Hot Yoga / Bikram Style
('a09a0017-0001-4000-8000-000000000023', 'Hot Yoga Style (26 Poses)', 'Bikram-inspired sequence of 26 postures. Designed for heated room but can be done anywhere. Systematic full-body practice.', 'mobility', 'intermediate', 60, '{
  "blocks": [
    {"name": "Breathing", "sequence": 0, "exercises": [
      {"name": "Pranayama (Standing Deep Breathing)", "duration": "3 min", "notes": "Arms overhead, elbows touching."}
    ]},
    {"name": "Standing Series", "sequence": 1, "exercises": [
      {"name": "Half Moon with Backbend", "duration": "1 min"},
      {"name": "Awkward Pose (Chair)", "sets": 3, "duration": "30 sec each variation"},
      {"name": "Eagle Pose", "duration": "30 sec each side"},
      {"name": "Standing Head to Knee", "duration": "30 sec each side"},
      {"name": "Standing Bow", "duration": "30 sec each side"},
      {"name": "Balancing Stick", "duration": "10 sec each side"},
      {"name": "Standing Separate Leg Stretching", "duration": "1 min"},
      {"name": "Triangle Pose", "duration": "30 sec each side"},
      {"name": "Standing Separate Leg Head to Knee", "duration": "30 sec each side"},
      {"name": "Tree Pose", "duration": "30 sec each side"},
      {"name": "Toe Stand", "duration": "30 sec each side"}
    ]},
    {"name": "Floor Series", "sequence": 2, "exercises": [
      {"name": "Dead Body Pose (Savasana)", "duration": "2 min"},
      {"name": "Wind Removing Pose", "duration": "30 sec each variation"},
      {"name": "Cobra Pose", "sets": 2, "duration": "20 sec"},
      {"name": "Locust Pose", "sets": 2, "duration": "20 sec"},
      {"name": "Full Locust", "duration": "20 sec"},
      {"name": "Bow Pose", "sets": 2, "duration": "20 sec"},
      {"name": "Fixed Firm Pose", "duration": "30 sec"},
      {"name": "Half Tortoise", "duration": "30 sec"},
      {"name": "Camel Pose", "duration": "30 sec"},
      {"name": "Rabbit Pose", "duration": "30 sec"},
      {"name": "Head to Knee with Stretching", "duration": "30 sec each side"},
      {"name": "Spine Twist", "duration": "30 sec each side"}
    ]},
    {"name": "Closing", "sequence": 3, "exercises": [
      {"name": "Blowing in Firm (Kapalabhati)", "duration": "1 min"},
      {"name": "Final Savasana", "duration": "2 min"}
    ]}
  ]
}', ARRAY['yoga', 'hot-yoga', 'bikram', '26-poses', 'systematic', 'intermediate'], 'hot_yoga.md'),

-- 5-Minute Desk Yoga
('a09a0018-0001-4000-8000-000000000024', '5-Minute Desk Break Yoga', 'Quick yoga reset you can do anywhere. Standing and seated stretches for instant tension relief.', 'mobility', 'beginner', 5, '{
  "blocks": [
    {"name": "Quick Stretches", "sequence": 0, "exercises": [
      {"name": "Standing Side Stretch", "duration": "30 sec each side"},
      {"name": "Standing Forward Fold", "duration": "30 sec"},
      {"name": "Neck Rolls", "sets": 1, "reps": "3 each direction"},
      {"name": "Shoulder Shrugs", "sets": 1, "reps": "5"},
      {"name": "Seated Twist", "duration": "30 sec each side"},
      {"name": "Wrist Stretches", "duration": "30 sec"},
      {"name": "Deep Breaths", "sets": 5, "notes": "Inhale 4, exhale 6."}
    ]}
  ]
}', ARRAY['yoga', 'quick', '5-minute', 'desk', 'office', 'break'], 'desk_yoga_5min.md'),

-- Yoga Flow for Flexibility
('a09a0019-0001-4000-8000-000000000025', 'Flexibility Flow', 'Comprehensive practice targeting major muscle groups. Progressive stretching from warm-up to deep holds.', 'mobility', 'intermediate', 50, '{
  "blocks": [
    {"name": "Warmup", "sequence": 0, "exercises": [
      {"name": "Sun Salutation A", "sets": 5, "notes": "Warm up muscles."},
      {"name": "Sun Salutation B", "sets": 3}
    ]},
    {"name": "Hamstrings", "sequence": 1, "exercises": [
      {"name": "Standing Forward Fold", "duration": "1 min"},
      {"name": "Wide-Legged Forward Fold", "duration": "1 min"},
      {"name": "Pyramid Pose", "duration": "1 min each side"},
      {"name": "Seated Forward Fold", "duration": "2 min"},
      {"name": "Hanumanasana (Splits) Prep", "duration": "2 min each side"}
    ]},
    {"name": "Hips", "sequence": 2, "exercises": [
      {"name": "Low Lunge", "duration": "1 min each side"},
      {"name": "Pigeon Pose", "duration": "3 min each side"},
      {"name": "Frog Pose", "duration": "3 min"}
    ]},
    {"name": "Spine & Shoulders", "sequence": 3, "exercises": [
      {"name": "Thread the Needle", "duration": "1 min each side"},
      {"name": "Puppy Pose", "duration": "2 min"},
      {"name": "Camel Pose", "duration": "1 min"},
      {"name": "Wheel Pose", "sets": 3, "duration": "30 sec", "notes": "Optional."}
    ]},
    {"name": "Cool Down", "sequence": 4, "exercises": [
      {"name": "Supine Twist", "duration": "2 min each side"},
      {"name": "Happy Baby", "duration": "2 min"},
      {"name": "Savasana", "duration": "5 min"}
    ]}
  ]
}', ARRAY['yoga', 'flexibility', 'stretching', 'splits', 'deep-stretch', 'intermediate'], 'flexibility_flow.md');

-- Verify insert
SELECT COUNT(*) as yoga_template_count FROM system_workout_templates WHERE 'yoga' = ANY(tags);
