import React from 'react';
import { Composition } from 'remotion';
import { ExerciseDemo } from './ExerciseDemo';

// Register all exercise video compositions

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* Squat Demo */}
      <Composition
        id="Squat"
        component={ExerciseDemo}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{
          exerciseName: 'Back Squat',
          exerciseType: 'squat' as const,
          formCues: [
            'Feet shoulder-width apart',
            'Brace your core tight',
            'Break at hips and knees together',
            'Keep chest up throughout',
            'Drive through mid-foot',
            'Stand tall at the top',
          ],
          backgroundColor: '#FFFFFF',
        }}
      />

      {/* Deadlift Demo */}
      <Composition
        id="Deadlift"
        component={ExerciseDemo}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{
          exerciseName: 'Conventional Deadlift',
          exerciseType: 'deadlift' as const,
          formCues: [
            'Bar over mid-foot',
            'Grip just outside legs',
            'Engage lats, brace core',
            'Push the floor away',
            'Keep bar close to body',
            'Lock out hips at top',
          ],
          backgroundColor: '#FFFFFF',
        }}
      />

      {/* Overhead Press Demo */}
      <Composition
        id="OverheadPress"
        component={ExerciseDemo}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{
          exerciseName: 'Overhead Press',
          exerciseType: 'overhead-press' as const,
          formCues: [
            'Grip slightly wider than shoulders',
            'Bar at collarbone height',
            'Brace core, squeeze glutes',
            'Press straight up',
            'Move head back, then forward',
            'Lock out at the top',
          ],
          backgroundColor: '#FFFFFF',
        }}
      />

      {/* Pull-up Demo */}
      <Composition
        id="PullUp"
        component={ExerciseDemo}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{
          exerciseName: 'Pull-up',
          exerciseType: 'pull-up' as const,
          formCues: [
            'Grip slightly wider than shoulders',
            'Start from dead hang',
            'Engage lats, pull elbows down',
            'Lead with your chest',
            'Chin over the bar',
            'Control the descent',
          ],
          backgroundColor: '#FFFFFF',
        }}
      />

      {/* Bench Press Demo (existing) */}
      <Composition
        id="BenchPress"
        component={ExerciseDemo}
        durationInFrames={900}
        fps={30}
        width={1080}
        height={1080}
        defaultProps={{
          exerciseName: 'Barbell Bench Press',
          exerciseType: 'bench-press' as const,
          formCues: [
            'Keep feet flat on the floor',
            'Maintain natural arch in lower back',
            'Grip bar slightly wider than shoulders',
            'Lower bar to mid-chest',
            'Drive through feet as you press',
            'Lock out arms at the top',
          ],
          backgroundColor: '#FFFFFF',
        }}
      />
    </>
  );
};
