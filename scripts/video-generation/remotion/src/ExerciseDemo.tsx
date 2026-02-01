import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
  spring,
} from 'remotion';

// Exercise demonstration video component
// Renders a stick figure animation with form cues

interface ExerciseDemoProps {
  exerciseName: string;
  exerciseType: 'bench-press' | 'squat' | 'deadlift' | 'overhead-press' | 'pull-up';
  formCues: string[];
  backgroundColor?: string;
}

export const ExerciseDemo: React.FC<ExerciseDemoProps> = ({
  exerciseName,
  exerciseType,
  formCues,
  backgroundColor = '#FFFFFF',
}) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();

  // Animation phases (as percentage of total duration)
  const setupPhase = 0.15; // 15% - show exercise name
  const demoPhase = 0.7; // 70% - demonstrate movement
  const cuePhase = 0.15; // 15% - show form cues

  const setupFrames = Math.floor(durationInFrames * setupPhase);
  const demoFrames = Math.floor(durationInFrames * demoPhase);

  return (
    <AbsoluteFill style={{ backgroundColor }}>
      {/* Exercise Name Header */}
      <ExerciseHeader
        name={exerciseName}
        frame={frame}
        setupFrames={setupFrames}
        fps={fps}
      />

      {/* Stick Figure Animation */}
      <StickFigure
        exerciseType={exerciseType}
        frame={frame}
        startFrame={setupFrames}
        endFrame={setupFrames + demoFrames}
        fps={fps}
      />

      {/* Form Cues */}
      <FormCueOverlay
        cues={formCues}
        frame={frame}
        startFrame={setupFrames + demoFrames}
        fps={fps}
      />

      {/* Progress Bar */}
      <ProgressBar frame={frame} totalFrames={durationInFrames} />
    </AbsoluteFill>
  );
};

// Exercise name header with fade in
const ExerciseHeader: React.FC<{
  name: string;
  frame: number;
  setupFrames: number;
  fps: number;
}> = ({ name, frame, setupFrames, fps }) => {
  const opacity = interpolate(frame, [0, fps * 0.5], [0, 1], {
    extrapolateRight: 'clamp',
  });

  const fadeOut = interpolate(
    frame,
    [setupFrames - fps * 0.3, setupFrames],
    [1, 0],
    { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }
  );

  return (
    <div
      style={{
        position: 'absolute',
        top: 80,
        left: 0,
        right: 0,
        textAlign: 'center',
        opacity: Math.min(opacity, fadeOut),
      }}
    >
      <h1
        style={{
          fontFamily: 'SF Pro Display, -apple-system, sans-serif',
          fontSize: 64,
          fontWeight: 700,
          color: '#1a1a1a',
          margin: 0,
        }}
      >
        {name}
      </h1>
    </div>
  );
};

// Animated stick figure
const StickFigure: React.FC<{
  exerciseType: string;
  frame: number;
  startFrame: number;
  endFrame: number;
  fps: number;
}> = ({ exerciseType, frame, startFrame, endFrame, fps }) => {
  const isActive = frame >= startFrame && frame < endFrame;
  const localFrame = frame - startFrame;
  const cycleDuration = fps * 2; // 2 seconds per rep

  // Calculate animation progress (0-1, looping)
  const cycleProgress = (localFrame % cycleDuration) / cycleDuration;
  const phase = Math.sin(cycleProgress * Math.PI * 2) * 0.5 + 0.5;

  if (!isActive) return null;

  // Get exercise-specific positions and equipment
  const { positions, equipment } = getExerciseData(exerciseType, phase);

  const strokeWidth = 8;
  const jointRadius = 12;
  const headRadius = 40;
  const color = '#333333';

  return (
    <svg
      width="600"
      height="500"
      viewBox="0 0 600 500"
      style={{
        position: 'absolute',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
      }}
    >
      {/* Equipment */}
      {equipment}

      {/* Body - torso */}
      <line
        x1={positions.shoulder.x}
        y1={positions.shoulder.y}
        x2={positions.hip.x}
        y2={positions.hip.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />

      {/* Head */}
      <circle
        cx={positions.head.x}
        cy={positions.head.y}
        r={headRadius}
        fill="none"
        stroke={color}
        strokeWidth={strokeWidth}
      />

      {/* Arms */}
      <line
        x1={positions.shoulder.x}
        y1={positions.shoulder.y}
        x2={positions.leftElbow.x}
        y2={positions.leftElbow.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />
      <line
        x1={positions.leftElbow.x}
        y1={positions.leftElbow.y}
        x2={positions.leftHand.x}
        y2={positions.leftHand.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />
      <line
        x1={positions.shoulder.x}
        y1={positions.shoulder.y}
        x2={positions.rightElbow.x}
        y2={positions.rightElbow.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />
      <line
        x1={positions.rightElbow.x}
        y1={positions.rightElbow.y}
        x2={positions.rightHand.x}
        y2={positions.rightHand.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />

      {/* Legs */}
      <line
        x1={positions.hip.x}
        y1={positions.hip.y}
        x2={positions.leftKnee.x}
        y2={positions.leftKnee.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />
      <line
        x1={positions.leftKnee.x}
        y1={positions.leftKnee.y}
        x2={positions.leftFoot.x}
        y2={positions.leftFoot.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />
      <line
        x1={positions.hip.x}
        y1={positions.hip.y}
        x2={positions.rightKnee.x}
        y2={positions.rightKnee.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />
      <line
        x1={positions.rightKnee.x}
        y1={positions.rightKnee.y}
        x2={positions.rightFoot.x}
        y2={positions.rightFoot.y}
        stroke={color}
        strokeWidth={strokeWidth}
        strokeLinecap="round"
      />

      {/* Joints */}
      {[
        positions.shoulder,
        positions.leftElbow,
        positions.rightElbow,
        positions.hip,
        positions.leftKnee,
        positions.rightKnee,
      ].map((pos, i) => (
        <circle
          key={i}
          cx={pos.x}
          cy={pos.y}
          r={jointRadius}
          fill={color}
        />
      ))}
    </svg>
  );
};

// Get exercise-specific data
function getExerciseData(exerciseType: string, phase: number) {
  switch (exerciseType) {
    case 'squat':
      return getSquatData(phase);
    case 'deadlift':
      return getDeadliftData(phase);
    case 'overhead-press':
      return getOverheadPressData(phase);
    case 'pull-up':
      return getPullUpData(phase);
    case 'bench-press':
    default:
      return getBenchPressData(phase);
  }
}

// Bench Press
function getBenchPressData(phase: number) {
  const armExtension = phase;
  const elbowY = interpolate(armExtension, [0, 1], [280, 180]);
  const handY = interpolate(armExtension, [0, 1], [240, 100]);

  const positions = {
    head: { x: 230, y: 230 },
    shoulder: { x: 300, y: 230 },
    hip: { x: 400, y: 240 },
    leftElbow: { x: 240, y: elbowY },
    rightElbow: { x: 360, y: elbowY },
    leftHand: { x: 200, y: handY },
    rightHand: { x: 400, y: handY },
    leftKnee: { x: 450, y: 300 },
    rightKnee: { x: 480, y: 300 },
    leftFoot: { x: 430, y: 360 },
    rightFoot: { x: 500, y: 360 },
  };

  const equipment = (
    <>
      {/* Bench */}
      <rect x="100" y="280" width="400" height="20" rx="5" fill="#666666" />
      <rect x="130" y="300" width="20" height="60" fill="#888888" />
      <rect x="450" y="300" width="20" height="60" fill="#888888" />
      {/* Barbell */}
      <line x1={180} y1={handY} x2={420} y2={handY} stroke="#444444" strokeWidth={6} strokeLinecap="round" />
      <rect x={165} y={handY - 25} width="10" height="50" rx="2" fill="#222222" />
      <rect x={425} y={handY - 25} width="10" height="50" rx="2" fill="#222222" />
    </>
  );

  return { positions, equipment };
}

// Squat
function getSquatData(phase: number) {
  const squat = 1 - phase; // 0 = standing, 1 = squatted

  const hipY = interpolate(squat, [0, 1], [200, 300]);
  const kneeY = interpolate(squat, [0, 1], [300, 340]);
  const shoulderY = interpolate(squat, [0, 1], [120, 220]);
  const headY = interpolate(squat, [0, 1], [60, 160]);

  const positions = {
    head: { x: 300, y: headY },
    shoulder: { x: 300, y: shoulderY },
    hip: { x: 300, y: hipY },
    leftElbow: { x: 240, y: shoulderY + 20 },
    rightElbow: { x: 360, y: shoulderY + 20 },
    leftHand: { x: 260, y: shoulderY - 20 },
    rightHand: { x: 340, y: shoulderY - 20 },
    leftKnee: { x: 250, y: kneeY },
    rightKnee: { x: 350, y: kneeY },
    leftFoot: { x: 230, y: 420 },
    rightFoot: { x: 370, y: 420 },
  };

  const barY = shoulderY - 30;
  const equipment = (
    <>
      {/* Floor */}
      <line x1="100" y1="420" x2="500" y2="420" stroke="#CCCCCC" strokeWidth={4} />
      {/* Barbell on back */}
      <line x1={200} y1={barY} x2={400} y2={barY} stroke="#444444" strokeWidth={8} strokeLinecap="round" />
      <rect x={185} y={barY - 20} width="12" height="40" rx="2" fill="#222222" />
      <rect x={403} y={barY - 20} width="12" height="40" rx="2" fill="#222222" />
    </>
  );

  return { positions, equipment };
}

// Deadlift
function getDeadliftData(phase: number) {
  const lift = phase; // 0 = bent, 1 = standing

  const hipY = interpolate(lift, [0, 1], [320, 200]);
  const shoulderY = interpolate(lift, [0, 1], [260, 120]);
  const headY = interpolate(lift, [0, 1], [220, 60]);
  const kneeAngle = interpolate(lift, [0, 1], [340, 300]);
  const barY = interpolate(lift, [0, 1], [400, 320]);

  const positions = {
    head: { x: 280, y: headY },
    shoulder: { x: 300, y: shoulderY },
    hip: { x: 340, y: hipY },
    leftElbow: { x: 270, y: shoulderY + 60 },
    rightElbow: { x: 330, y: shoulderY + 60 },
    leftHand: { x: 260, y: barY - 10 },
    rightHand: { x: 340, y: barY - 10 },
    leftKnee: { x: 280, y: kneeAngle },
    rightKnee: { x: 380, y: kneeAngle },
    leftFoot: { x: 260, y: 420 },
    rightFoot: { x: 360, y: 420 },
  };

  const equipment = (
    <>
      {/* Floor */}
      <line x1="100" y1="420" x2="500" y2="420" stroke="#CCCCCC" strokeWidth={4} />
      {/* Barbell */}
      <line x1={160} y1={barY} x2={440} y2={barY} stroke="#444444" strokeWidth={8} strokeLinecap="round" />
      <circle cx={160} cy={barY} r="30" fill="none" stroke="#222222" strokeWidth={8} />
      <circle cx={440} cy={barY} r="30" fill="none" stroke="#222222" strokeWidth={8} />
    </>
  );

  return { positions, equipment };
}

// Overhead Press
function getOverheadPressData(phase: number) {
  const press = phase; // 0 = at shoulders, 1 = overhead

  const handY = interpolate(press, [0, 1], [140, 20]);
  const elbowY = interpolate(press, [0, 1], [180, 60]);

  const positions = {
    head: { x: 300, y: 100 },
    shoulder: { x: 300, y: 160 },
    hip: { x: 300, y: 280 },
    leftElbow: { x: 220, y: elbowY },
    rightElbow: { x: 380, y: elbowY },
    leftHand: { x: 200, y: handY },
    rightHand: { x: 400, y: handY },
    leftKnee: { x: 260, y: 360 },
    rightKnee: { x: 340, y: 360 },
    leftFoot: { x: 240, y: 440 },
    rightFoot: { x: 360, y: 440 },
  };

  const barY = handY;
  const equipment = (
    <>
      {/* Floor */}
      <line x1="100" y1="440" x2="500" y2="440" stroke="#CCCCCC" strokeWidth={4} />
      {/* Barbell */}
      <line x1={140} y1={barY} x2={460} y2={barY} stroke="#444444" strokeWidth={6} strokeLinecap="round" />
      <rect x={125} y={barY - 15} width="10" height="30" rx="2" fill="#222222" />
      <rect x={465} y={barY - 15} width="10" height="30" rx="2" fill="#222222" />
    </>
  );

  return { positions, equipment };
}

// Pull-up
function getPullUpData(phase: number) {
  const pull = phase; // 0 = hanging, 1 = pulled up

  const bodyY = interpolate(pull, [0, 1], [0, -100]);
  const elbowSpread = interpolate(pull, [0, 1], [40, 80]);

  const positions = {
    head: { x: 300, y: 140 + bodyY },
    shoulder: { x: 300, y: 200 + bodyY },
    hip: { x: 300, y: 320 + bodyY },
    leftElbow: { x: 300 - elbowSpread, y: 140 + bodyY },
    rightElbow: { x: 300 + elbowSpread, y: 140 + bodyY },
    leftHand: { x: 220, y: 50 },
    rightHand: { x: 380, y: 50 },
    leftKnee: { x: 280, y: 400 + bodyY },
    rightKnee: { x: 320, y: 400 + bodyY },
    leftFoot: { x: 270, y: 460 + bodyY },
    rightFoot: { x: 330, y: 460 + bodyY },
  };

  const equipment = (
    <>
      {/* Pull-up bar */}
      <line x1="150" y1="50" x2="450" y2="50" stroke="#444444" strokeWidth={10} strokeLinecap="round" />
      {/* Bar supports */}
      <line x1="150" y1="50" x2="150" y2="0" stroke="#666666" strokeWidth={6} />
      <line x1="450" y1="50" x2="450" y2="0" stroke="#666666" strokeWidth={6} />
    </>
  );

  return { positions, equipment };
}

// Form cue overlay
const FormCueOverlay: React.FC<{
  cues: string[];
  frame: number;
  startFrame: number;
  fps: number;
}> = ({ cues, frame, startFrame, fps }) => {
  const isActive = frame >= startFrame;
  if (!isActive || cues.length === 0) return null;

  const localFrame = frame - startFrame;
  const cueIndex = Math.min(
    Math.floor(localFrame / (fps * 1.5)),
    cues.length - 1
  );
  const currentCue = cues[cueIndex];

  const opacity = spring({
    fps,
    frame: localFrame % (fps * 1.5),
    config: { damping: 15 },
  });

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 100,
        left: 40,
        right: 40,
        opacity,
      }}
    >
      <div
        style={{
          backgroundColor: 'rgba(0, 122, 255, 0.9)',
          padding: '16px 24px',
          borderRadius: 12,
        }}
      >
        <p
          style={{
            fontFamily: 'SF Pro Text, -apple-system, sans-serif',
            fontSize: 28,
            fontWeight: 600,
            color: 'white',
            margin: 0,
            textAlign: 'center',
          }}
        >
          {currentCue}
        </p>
      </div>
    </div>
  );
};

// Progress bar at bottom
const ProgressBar: React.FC<{
  frame: number;
  totalFrames: number;
}> = ({ frame, totalFrames }) => {
  const progress = frame / totalFrames;

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 20,
        left: 40,
        right: 40,
        height: 4,
        backgroundColor: '#E0E0E0',
        borderRadius: 2,
      }}
    >
      <div
        style={{
          width: `${progress * 100}%`,
          height: '100%',
          backgroundColor: '#007AFF',
          borderRadius: 2,
        }}
      />
    </div>
  );
};

export default ExerciseDemo;
