;;
;; Fri Jun 18 17:47:40 2021
;; Generated for
;; https://github.com/agent-system/lecture2021/webots/projects/kxrl2t2l6a7h2/controllers/irteusgl/kxr-demo.l
;;
;;;
;;;  kxr robot for webots 2021
;;;  to be copied to webots controllers/irteusgl/kxr-demo.l
;;;
;;;  cd prog/rcb4eus/webots/worlds
;;;  webots kxrl2makabe-extern.wbt
;;;  irteusgl kxrwebots.l
;;;
(load "webotslib.l")
;;;
(setq TIME_STEP 32)
(defvar *init* nil)
(defvar *head-swing* nil)
(defvar *imu-show-state* nil)
(defun isnan (v) (and  (< v 0) (> v 0)))
(defun send+ (&rest args)
  ;;(when (find-method (car args) (cadr args))
  (send* args)
  (send *irtviewer* :draw-objects)
  (send-webots)
  ;;)
  )
(defun send! (&rest args)
  (when (find-method (car args) (cadr args))
    (send* args)
    (send-webots)
    (send *irtviewer* :draw-objects)
    )
  )
(defvar *butterfly* nil)
(defvar *butterfly-phase* 0.0)
(defvar *flutter* nil)
(defvar *flutter-range* 30.0)
(defvar *flutter-phase* 0.0)
(defmethod robot-model
  (:limb-start-orientation
   (&optional (limb :larm))
   (let* ((vv (send self :limb-vectors limb)))
     )
   )
  (:larm-shoulder-v
   (v)
   (setq v (normalize-vector v))
   (let* ((p (atan2 (elt v 0) (elt v 2)))
	  (pitch (if (> p 0) (+ p (- pi)) (+ p pi)))
	  (y (atan2 (elt v 0) (elt v 1)))
	  (roll (if (> y 0) (- pi/2 y) (+ pi/2 y)))
	  )
     (send self :larm-shoulder-p :joint-angle (rad2deg pitch))
     (send self :larm-shoulder-r :joint-angle (rad2deg roll))
     (list 'p (rad2deg p) 'y (rad2deg y) 'pitch (rad2deg pitch) 'roll (rad2deg roll))))
  (:rarm-shoulder-v
   (v)
   (setq v (normalize-vector v))
   (let* ((p (atan2 (elt v 0) (elt v 2)))
	  (pitch (if (> p 0) (+ p (- pi)) (+ p pi)))
	  (y (atan2 (elt v 0) (- (elt v 1))))
	  (roll (if (> y 0) (+ (- pi/2) y) (- (- pi/2) y))))
     (send self :rarm-shoulder-p :joint-angle (rad2deg pitch))
     (send self :rarm-shoulder-r :joint-angle (rad2deg roll))
     (list 'p (rad2deg p) 'y (rad2deg y) 'pitch (rad2deg pitch) 'roll (rad2deg roll))))
  (:spherical
   (dth dphi &optional (axis :z))
   (let* ((th (deg2rad dth)) (phi (deg2rad dphi)) (s-th (sin th))
	  (v (float-vector (* s-th (cos phi)) (* s-th (sin phi)) (cos th)))
	  (r (case
	      axis
	      (:x (rotation-matrix pi/2 :y))
	      (:-x (m* (diagonal #f(-1 1 1)) (rotation-matrix pi/2 :y)))
	      (:y (rotation-matrix -pi/2 :x))
	      (:-y (m* (diagonal #f(1 -1 1)) (rotation-matrix -pi/2 :x)))
	      (:z  (rotation-matrix 0 :x))
	      (:-z (m* (diagonal #f(1 1 -1)) (rotation-matrix 0 :x)))
	      (t  (rotation-matrix 0 :x)))))
     (transform r v)))
  (:arm-spherical
   (th phi)
   (send self :larm-shoulder-v (send self :spherical th phi :y))
   (send self :rarm-shoulder-v (send self :spherical th phi :-y)))
  (:leg-spherical
   (dth dphi &optional (limb :lleg))
   (let* ((v (send self :spherical dth dphi :-z))
	  (p (atan2 (- (elt v 0)) (- (elt v 2))))
	  (r (atan2 (elt v 1) (- (elt v 2)))))
     (send self limb :crotch-p :joint-angle (rad2deg p))
     (send self limb :crotch-r :joint-angle (rad2deg r))
     ))
  (:lleg-spherical (dth dphi) (send self :leg-spherical dth dphi :lleg))
  (:rleg-spherical (dth dphi) (send self :leg-spherical dth dphi :rleg))
  (:leg-flutter
   (th)
   (send self :lleg-spherical th 0)
   (send self :rleg-spherical (- th) 0))
  (:flutter
   (&optional (dphi 30)) ;; deg
   (when *flutter*
     (if (> (incf *flutter-phase* (incf dphi)) 360.0) (setq *flutter-phase* 0.0))
     (send! self :leg-flutter (* *flutter-range* (sin (deg2rad *flutter-phase*))))
     ))
  (:butterfly0 () (send self :arm-spherical 0 0))
  (:butterfly1 () (send self :arm-spherical 45 180))
  (:butterfly2 () (send self :arm-spherical 80 -110))
  (:butterfly3 () (send self :arm-spherical 80 -70))
  (:butterfly4 () (send self :arm-spherical 80 70))
  (:butterfly5 () (send self :arm-spherical 80 110))
  (:arm-up () (send! self :butterfly3))
  (:arm-down () (send! self :butterfly4))
  (:motion-file-exec
   (num)
   (setq motion-file (format nil "motions/~A-~A.motion" *robot-name* num))
   (format t ";; motion-file=~A~%" motion-file)
   (when (probe-file motion-file)
     (setq motion (wbu_motion_new motion-file))
     (wbu_motion_play motion)
     (let ((flag t))
       (while flag
	 (my_step)
	 ;;(format t ";; wbu_motion_is_over=~A~%" (wbu_motion_is_over motion))
	 (if (not (= (wbu_motion_is_over motion) 0)) (setq flag nil))
	 ))
     ))
  (:butterfly
   (&optional (dphi 30)) ;; deg
   (when *butterfly*
     (if (> (incf *butterfly-phase* (incf dphi)) 360.0) (setq *butterfly-phase* 0.0))
     (send! self :arm-spherical 80 *butterfly-phase*)
     ))
  (:limb-vectors
   (&optional (limb :larm))
   (let* ((ll (send self limb :links))
	  (vs (send-all ll :worldpos))
	  (p0 (pop vs)) ret)
     (dolist (p vs)
       (push (v- p p0) ret)
       (setq p0 p))
     (reverse ret)))
  )
(defmethod robot-model
  (:limb-vectors-length
   (&optional (limb :larm))   
   (let ((vs (send self :limb-vectors limb))
	 (len 0))
     (dolist (v vs) (incf len (norm v)))
     len))
  (:limb-box
   (&optional (limb :larm))
   (let* ((ll (send self limb :links))
	  (p (send (car ll) :worldpos))
	  (bl (flatten (send-all ll :bodies)))
	  (bs (send-all bl :box))
	  (b0 (pop bs)))
     (dolist (b bs) (setq b0 (send b0 :union b)))
     b0))
  (:limb-start-pos
   (&optional (limb :larm))   
   (send (car (send self limb :links)) :worldpos))
  (:limb-end-pos
   (&optional (limb :larm))   
   (send self limb :end-coords :worldpos))
  (:limb-length
   (&optional (limb :larm))
   (norm (v- (send self :limb-end-pos limb)
	     (send self :limb-start-pos limb))))
  )
(defmethod robot-model
  (:sit
   (&optional (goal 120) (a (send self :lleg-knee-p :joint-angle)))
   (if (< a goal) (send! self :send-squat (+ a 15))))
  (:stand
   (&optional (goal 20) (a (send self :lleg-knee-p :joint-angle)))
   (if (> a goal) (send! self :send-squat (- a 15))))
  (:send-squat
   (knee-angle)
   (send self :set-joint-angle :lleg-crotch-p (- (/ knee-angle 2.0)))
   (send self :set-joint-angle :rleg-crotch-p (- (/ knee-angle 2.0)))
   (send self :set-joint-angle :lleg-knee-p knee-angle)
   (send self :set-joint-angle :rleg-knee-p knee-angle)
   (send self :set-joint-angle :lleg-ankle-p (- (/ knee-angle 2.0)))
   (send self :set-joint-angle :rleg-ankle-p (- (/ knee-angle 2.0))))
  (:set-joint-angle
   (j angle)
   (when (and (find-method self j) (send self j))
     (send self j :joint-angle angle)))
  )
(defun set-joint-angle (j angle) (send *robot* :set-joint-angle j angle))
(defun send-webots nil
  (dolist (j (send *robot* :joint-list))
    (cond
     ((memq (send j :get :joint-type) (list :wheel :thrust))
      (format t ";; joint j=~A type=~A~%" j (send j :get :joint-type))
      (wb_motor_set_position (get j :device) infinity)
      (wb_motor_set_velocity (get j :device) (deg2rad (send j :joint-angle))))
     (t (wb_motor_set_position (get j :device) (deg2rad (send j :joint-angle)))))
    )
  )

(defun read-webots nil
  (dolist (j (send *robot* :joint-list))
    (unless (eq :wheel (send j :get :joint-type))
      (send j :joint-angle
	    (rad2deg (wb_position_sensor_get_value (get j :sensor)))))
    ;;(format t ";; position=~A , j=~A~%" (wb_position_sensor_get_value (get j :sensor)) j)
    )
  (when *imu-show-state*
    (format t ";; time_step=~A~%" time_step)
    (when (> *gyro* 0)
      (setq *gyro-vec* (cout-float-vector (wb_gyro_get_values *gyro*) 3))
      (format t ";; *gyro*=~A *gyro-vec*=~A~%" *gyro* *gyro-vec*))
    (when (> *acc* 0)
      (setq *acc-vec* (cout-float-vector (wb_accelerometer_get_values *acc*) 3))
      (format t ";; *acc*=~A *acc-vec*=~A~%" *acc* *acc-vec*))
    (when (> *imu* 0)
      (setq *imu-vec* (cout-float-vector (wb_inertial_unit_get_roll_pitch_yaw *imu*) 3))
      (format t ";; *imu*=~A *imu-vec*=~A~%" *imu* *imu-vec*))
    (when (> *compass* 0)
      (setq *compass-vec* (cout-float-vector (wb_compass_get_values *compass*) 3))
      (format t ";; *compass*=~A *compass-vec*=~A~%" *compass* *compass-vec*))
    ))

(defun recognition-step (camera)
  (when (> camera 0)
    (setq number_of_objects (wb_camera_recognition_get_number_of_objects camera))
    (when (> number_of_objects camera)
      (format t "~%** Recognized ~d objects in camera(~A).~%" number_of_objects camera)
      (setq *robjs* (instantiate vector number_of_objects))
      (dotimes (i number_of_objects)
	(setf (elt *robjs* i)
	      (cout-cstruct (+ (wb_camera_recognition_get_objects camera)
			       (* (send wbcamerarecognitionobject :size) i))
			    wbcamerarecognitionobject))
	(format t "*** Model of object ~d: <~A>~%" i (cout-string (send (elt *robjs* i) :get+ 'model)))
	(format t "  Id of object ~d: ~d~%" i (send (elt *robjs* i) :get+ 'id))
	(format t "  Relative position of object ~d: ~A~%" i
		(send (elt *robjs* i) :get+ 'position))
	;; 
	(format t "  Relative orientation of object ~d: ~A~%" i (send (elt *robjs* i) :get+ 'orientation))
	(format t "  Size of object ~d: ~A~%" i (send (elt *robjs* i) :get+ 'size))
	(format t "  Position of the object ~d on the camera image: ~A~%" i
		(send (elt *robjs* i) :get+ 'position_on_image)) ;; position_on_image[0,1]
	(format t "  Size of the object ~d on the camera image: ~A~%" i
		(send (elt *robjs* i) :get+ 'size_on_image)) ;; .size_on_image[0],[1]
	(dotimes (j (send (elt *robjs* i) :get+ 'number_of_colors));; number_of_colors
	  (format t "  Color ~d/~d: ~A~%" (+ j 1)
		  (send (elt *robjs* i) :get+ 'number_of_colors)
		  (cout-float-vector
		   (+ (send (elt *robjs* i) :get+ 'colors)
		      (* (byte-size :double) 3 j))
		   3))))
      )
    ))
(setq *pan* 0.0 *tilt* 0.0)
(defun head-swing nil
  (when *head-swing*
    (if (> (incf *pan* 3.0) 360) (setq *pan* 0))
    (if (> (incf *tilt* 90.0) 360) (setq *tilt* 0))
    (if (find-method *robot* :head-neck-y)
	(send *robot* :head-neck-y :joint-angle (* 80 (sin (deg2rad *pan*)))))
    (send! *robot* :head-neck-p :joint-angle (* -40 (sin (deg2rad *tilt*))))
    ))
(defun char-check (new_key c)
  (cond
   ((> c #\z)
    (= new_key c))
   ((>= c #\a)
    (= new_key (+ #\A (- c #\a))))
   ((and (= (logand #x10000 new_key) #x10000)
	 (= (logand #xffff new_key) c)))
   (t (= new_key c))))


(defun key-check (&rest args)
  (some #'(lambda (c) (char-check new_key c)) args))
(setq *motion-i* 0)
(setq
 *key-command-table*
 '(
   (WB_KEYBOARD_LEFT (send! *robot* :larm-shoulder-v #f(0 1 0)))
   (WB_KEYBOARD_RIGHT (send! *robot* :rarm-shoulder-v #f(0 -1 0)))
   (WB_KEYBOARD_UP (send! *robot* :forward 100))
   (WB_KEYBOARD_DOWN (send! *robot* :forward -100)) ;; mm
   ("?" (help-keymap))
   ("a" (send *robot* :motion-file-exec 20)) ;; greeting
   ("A" (send *robot* :motion-file-exec 21)) ;; swing arm
   ("b" (setq *butterfly* (not *butterfly*)))
   ("C" (send! *robot* :to-car))
   ("c" (send! *robot* :to-humanoid))
   ("d" (send! *robot* :arm-down))
   ("f" (setq *flutter* (not *flutter*)))
   ("h" (setq *head-swing* (not *head-swing*)))
   ("i" (setq *imu-show-state* (not *imu-show-state*)))
   ("J" (send! *robot* :fly -500))
   ("j" (send! *robot* :fly 500))
   ("g" (send *robot* :motion-file-exec 14)) ;; get up from face-down
   ("G" (send *robot* :motion-file-exec 15)) ;; get up from face-up
   ("k" (send *robot* :motion-file-exec 25)) ;; kick left
   ("K" (send *robot* :motion-file-exec 26)) ;; kick right
   ("n" (send! *robot* :neutral))
   ("-" (send *robot* :motion-file-exec *motion-i*) (decf *motion-i*))
   ("+" (send *robot* :motion-file-exec *motion-i*) (incf *motion-i*))
   ("p" (send *robot* :motion-file-exec 22)) ;; push up
   ("P" (send *robot* :motion-file-exec 24)) ;; pity
   ("w" (send *robot* :motion-file-exec 23)) ;; happy
   ("r" (send! *robot* :reset-pose))
   ("s" (send! *robot* :sit))
   ("S" (send! *robot* :stand))
   ("t" (send *robot* :motion-file-exec 10)) ;; walk to left
   ("T" (send *robot* :motion-file-exec 11)) ;; walk to right
   ;;("t" (send! *robot* :turn 30))
   ;;("T" (send! *robot* :turn -30))
   ("u" (send! *robot* :arm-up))
   (" " (send! *robot* :butterfly0))
   ("0" (send! *robot* :butterfly0))
   ("1" (send! *robot* :butterfly1))
   ("2" (send! *robot* :butterfly2))
   ("3" (send! *robot* :butterfly3))
   ("4" (send! *robot* :butterfly4))
   ("5" (send! *robot* :butterfly5))
   ("6" (send *robot* :motion-file-exec 6))
   ("7" (send *robot* :motion-file-exec 7))
   ("8" (send *robot* :motion-file-exec 8))
   ("9" (send *robot* :motion-file-exec 9))
   ((< new_key #x10000)
    (format t "keyboard space: i=~d key=~d~%" i new_key))
   ))
(defun read-keyboard nil
  (setq new_key (wb_keyboard_get_key))
  (when (and (> new_key 0) (not (= new_key prev_key)))
    (catch :read-keyboard
      (dolist (tab *key-command-table*)
	(when
	    (or
	     (and (symbolp (car tab)) (key-check (symbol-value (car tab))))
	     (and (stringp (car tab)) (key-check (elt (car tab) 0)))
	     (and (numberp (car tab)) (key-check (car tab)))
	     (and (consp (car tab)) (fboundp (car (car tab))) (eval (car tab))))
	  (dolist (com (cdr tab)) (eval com))
	  (format t ";; tab=~A~%" tab)
	  (throw :read-keyboard t)))
      )
    (setq prev_key new_key))
  )
(defun help-keymap nil (pprint *key-command-table*))

(defun main-init (&optional fname)
  (wb_robot_init)
  (setq *robot-name* (wb_robot_get_name))
  (format t ";; *robot-name*=~S~%" *robot-name*) ;; webots/projects/kxrxxx/irteusgl
  (format t ";; TIME_STEP=~S~%" TIME_STEP)
  ;;(setq TIME_STEP (round (wb_robot_get_basic_time_step)))
  ;;(format t ";; basic TIME_STEP=~S~%" TIME_STEP)
  (setq n_devices (wb_robot_get_number_of_devices))
  (dotimes (i n_devices)
    (setq d (wb_robot_get_device_by_index i))
    (format t ";; i:~A name:~S~%" i (wb_device_get_name d))
    )
  (load (format nil "~A.l" *robot-name*))
  (if (probe-file (format nil "~A-motions.l" *robot-name*))
      (load (format nil "~A-motions.l" *robot-name*)))
  (setq *robot* (funcall (read-from-string *robot-name*)))
  (objects (list *robot*))
  (dolist (j (send *robot* :joint-list))
    (setq n (send j :name))
    (setq n (string-downcase (if (symbolp n) (symbol-name n) n)))
    (send j :put :device (wb_robot_get_device n))
    (send j :put :sensor (wb_robot_get_device (format nil "~A_sensor" n)))
    (format t ";; joint name=~S :device=~S~%" n (get j :device))
    (if (get j :sensor)
	(wb_position_sensor_enable (get j :sensor) TIME_STEP))
    ;;(wb_motor_enable_position (get j :device) TIME_STEP)
    )
  (send *robot* :reset-pose)
  (setq *camera0* (wb_robot_get_device "camera_camera0_camera"))
  (when (> *camera0* 0)
    (wb_camera_enable *camera0* time_step)
    (wb_camera_recognition_enable *camera0* TIME_STEP)
    (setq *camera0-width* (wb_camera_get_width *camera0*))
    (setq *camera0-height* (wb_camera_get_height *camera0*))
    (setq *camera0-fstring* (webots-camera-fstring *camera0*))
    (format t "fstring length=~S~%" (length *camera0-fstring*))
    (print_camera_image *camera0*)
    (format t "camera0 width=~A height=~A~%" *camera0-width* *camera0-height*)
    )
  (setq *camera1* (wb_robot_get_device "camera_camera1_camera"))
  (when (> *camera1* 0)
    (wb_camera_enable *camera1* time_step)
    (wb_camera_recognition_enable *camera1* TIME_STEP)
    (setq *camera1-width* (wb_camera_get_width *camera1*))
    (setq *camera1-height* (wb_camera_get_height *camera1*))
    (setq *camera1-fstring* (webots-camera-fstring *camera1*))
    (format t "fstring length=~S~%" (length *camera1-fstring*))
    (print_camera_image *camera1*)
    (format t "camera1 width=~A height=~A~%" *camera1-width* *camera1-height*)
    )
  (when (> (setq *gyro* (wb_robot_get_device "imu_gyrometer_topic gyro")) 0)
    (format t ";; *gyro*=~A~%" *gyro*)
    (wb_gyro_enable *gyro* TIME_STEP))
  (when (> (setq *acc* (wb_robot_get_device "imu_gyrometer_topic accelerometer")) 0)
    (format t ";; *acc*=~A~%" *acc*)
    (wb_accelerometer_enable *acc* TIME_STEP))
  (when (> (setq *imu* (wb_robot_get_device "imu_gyrometer_topic inertialunit")) 0)
    (format t ";; *imu-vec*=~A~%" *imu*)
    (wb_inertial_unit_enable *imu* TIME_STEP))
  (when (> (setq *compass* (wb_robot_get_device "imu_gyrometer_topic compass")) 0)
    (format t ";; *compass*=~A~%" *compass*)
    (wb_compass_enable *compass* TIME_STEP))
  ;;(set-joint-angle :larm-shoulder-r 90.0)
  ;;(set-joint-angle :rarm-shoulder-r -90.0)
  (send *robot* :neutral)
  (send-webots)
  (wb_keyboard_enable TIME_STEP)
  (setq prev_key 0 i 0)
  (setq *init* t))
(defun main nil
  (unless *init* (main-init))
  (do-until-key (main-step)))
(defun my_step nil
  (wb_robot_step (round TIME_STEP))  
  (send *irtviewer* :draw-objects)
  (x::window-main-one)
  ;;(unix::usleep (* time_step 1000))
  )
(defun main-step nil
  (my_step)
  (read-webots)
  (recognition-step *camera0*)
  (recognition-step *camera1*)
  (head-swing)
  (when (fboundp 'walking-control) (walking-control (* 1e-3 time_step)))
  (when *butterfly* (send *robot* :butterfly))
  (when *flutter* (send *robot* :flutter))
  (read-keyboard)
  )
(defun itimer-on nil
  (unless *init* (main-init))
  (setq *top-selector-interval* 0.01)
  (pushnew 'main-step *timer-job*))
(defun itimer-off nil
  (setq *timer-job* (remove 'main-step *timer-job*)))
(defun activated-webots-count ()
  (1- (read (piped-fork "ps augx | grep bin/webots-bin | grep wbt| wc"))))
(when (> (activated-webots-count) 0)
  ;;(main)
  (itimer-on))


