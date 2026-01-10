-- Update body comp records to use correct patient ID
UPDATE body_comp_measurements 
SET patient_id = 'bc9d4832-f338-47d6-b5bb-92b118991ded'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';
