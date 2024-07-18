% Source: https://github.com/sparkfun/OpenLog_Artemis/blob/main/Firmware/Test%20Sketches/IMU_DMP_Quat6/IMU_DMP_Quat6.ino
% Lines 225-243
% returns roll pitch and yaw in degrees

function euler = quat2euler(q1, q2, q3)
    q0 = sqrt( 1 - ((q1 .* q1) + (q2 .* q2) + (q3 .* q3)));
    q0 = abs(q0);
    
    q2sqr = q2 .* q2;
    
    % roll (x-axis rotation)
    t0 = 2 * (q0 .* q1 + q2 .* q3);
    t1 = 1 - 2 .* (q1 .* q1 + q2sqr);
    roll = atan2(t0, t1) * 180 / pi;

    % pitch (y-axis rotation)
    t2 = 2 * (q0 .* q2 - q3 .* q1);
    %t2 = min(t2, 1);
    %t2 = max(t2, -1);
    t2 = t2.*(abs(t2) < 1) + sign(t2).*1.*(abs(t2) > 1);
    pitch = asin(t2) * 180.0 / pi;

    % yaw (z-axis rotation)
    t3 = 2 * (q0 .* q3 + q1 .* q2);
    t4 = 1 - 2 * (q2sqr + q3 .* q3);
    yaw = atan2(t3, t4) * 180.0 / pi;

    euler = {roll, pitch, yaw};
end