;;;*****************
;;;* Configuration *
;;;*****************


;;; ***************************
;;; * DEFTEMPLATES & DEFFACTS *
;;; ***************************

(deftemplate MAIN::text-for-id
   (slot id)
   (slot text))

(deftemplate UI-state
   (slot id (default-dynamic (gensym*)))
   (slot display)
   (slot relation-asserted (default none))
   (slot response (default none))
   (multislot valid-answers)
   (multislot display-answers)
   (slot state (default middle)))

;;;***************************
;;;* DEFFUNCTION DEFINITIONS *
;;;***************************

(deffunction MAIN::find-text-for-id (?id)
   ;; Search for the text-for-id fact
   ;; with the same id as ?id
   (bind ?fact
      (find-fact ((?f text-for-id))
                  (eq ?f:id ?id)))
   (if ?fact
      then
      (fact-slot-value (nth$ 1 ?fact) text)
      else
      ?id))

(deffunction MAIN::translate-av (?values)
   ;; Create the return value
   (bind ?result (create$))
   ;; Iterate over each of the allowed-values
   (progn$ (?v ?values)
      ;; Find the associated text-for-id fact
      (bind ?nv
         (find-text-for-id ?v))
      ;; Add the text to the return value
      (bind ?result (create$ ?result ?nv)))
   ;; Return the return value
   ?result)

(deffunction MAIN::replace-spaces (?str)
   (bind ?len (str-length ?str))
   (bind ?i (str-index " " ?str))
   (while (neq ?i FALSE)
      (bind ?str (str-cat (sub-string 1 (- ?i 1) ?str) "-" (sub-string (+ ?i 1) ?len ?str)))
      (bind ?i (str-index " " ?str)))
   ?str)

(deffunction MAIN::sym-cat-multifield (?values)
   (bind ?rv (create$))
   (progn$ (?v ?values)
      (bind ?rv (create$ ?rv (sym-cat (replace-spaces ?v)))))
   ?rv)

(deffunction MAIN::multifield-to-delimited-string (?mv ?delimiter)
   (bind ?rv "")
   (bind ?first TRUE)
   (progn$ (?v ?mv)
      (if ?first
         then
         (bind ?first FALSE)
         (bind ?rv (str-cat ?v))
         else
         (bind ?rv (str-cat ?rv ?delimiter ?v))))
   ?rv)

;;;*****************
;;;* STATE METHODS *
;;;*****************

;;; GUI target (iOS and JNI)

(defmethod handle-state ((?state SYMBOL (eq ?state greeting))
                         (?message LEXEME)
                         (?relation-asserted SYMBOL)
                         (?valid-answers MULTIFIELD))
   (assert (UI-state (display ?message)
                     (relation-asserted greeting)
                     (state ?state)
                     (valid-answers yes)
                     (display-answers yes)))
   (halt))

(defmethod handle-state ((?state SYMBOL (eq ?state interview))
                         (?message LEXEME)
                         (?relation-asserted SYMBOL)
                         (?response PRIMITIVE)
                         (?valid-answers MULTIFIELD)
                         (?display-answers MULTIFIELD))
   (assert (UI-state (display ?message)
                     (relation-asserted ?relation-asserted)
                     (state ?state)
                     (response ?response)
                     (valid-answers ?valid-answers)
                     (display-answers ?display-answers)))
   (halt))

(defmethod handle-state ((?state SYMBOL (eq ?state conclusion))
                         (?display LEXEME))
   (assert (UI-state (display ?display)
                     (state ?state)
                     (valid-answers)
                     (display-answers)))
   (halt))

;;;****************
;;;* STARTUP RULE *
;;;****************

(defrule system-banner ""
  (not (greeting yes))
  =>
  (handle-state greeting
                "Welcome to the after-work drink expert system"
                greeting
                (create$)))

;;;***************
;;;* QUERY RULES *
;;;***************
(defrule determine-drinking-buddy ""

   (greeting yes)
   (not (drink-with ?))
   =>
   (bind ?answers (create$ boss college client_business_contact group))
   (handle-state interview
                 "Who are you going to drink with?"
                 drink-with
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-official-function ""

   (drink-with group)
   (not (official-function ?))

   =>

   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is it a official function"
                 official-function
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-function-type ""

   (official-function yes)
   (not (function-type ?))

   =>

   (bind ?answers (create$ holiday_party performance_reward going_away_party))
   (handle-state interview
                 "it's a"
                 function-type
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-major-celebration ""

   (function-type performance_reward)
   (not (major-celebration ?))

   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is it a major celebration"
                 major-celebration
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-comfortable-get-wasted ""
    (or (function-type holiday_party)
   (major-celebration yes))
   (not (get-wasted ?))

   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Can you comfortably get wasted"
                 get-wasted
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-friday-night ""
    (get-wasted yes)
    (not (friday-night ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is it a friday night"
                 friday-night
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-planning-to-work ""
    (get-wasted yes)
    (not (planning-work ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you planning to work for a long time"
                 planning-work
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-like-person ""
    (function-type going_away_party)
    (not (like-person ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Do you like this person?"
                 like-person
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-like-people ""
    (official-function no)
    (not (like-person ?))
   =>
   (bind ?answers (create$ no eh))
   (handle-state interview
                 "Do you like these people?"
                 like-people
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-write-off ""
    (like-people eh)
    (not (write-off ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Can you write this off?"
                 write-off
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-trying-close-deal ""
    (drink-with client_business_contact)
    (not (close-deal ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "You're trying to close a deal..."
                 close-deal
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-expense-big ""
    (close-deal yes)
    (not (expense-big ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is your expense account big?"
                 expense-big
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-take-to-dinner ""
    (expense-big yes)
    (not (take-to-dinner ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Do you have to take them to dinner after?"
                 take-to-dinner
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-stay-on-radar ""
    (close-deal no)
    (not (stay-radar ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you schmoozing to stay on this person's radar?"
                 stay-radar
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-he-drinker ""
    (stay-radar yes)
    (not (he-drinker ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is he or she a good drinker?"
                 he-drinker
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-they-Mormon ""
    (he-drinker no)
    (not (mormon ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are they mormon?"
                 mormon
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))
(defrule determine-feel-obligated ""
    (he-drinker yes)
    (not (feel-obligated ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Do you feel obligated to keep up with this person?"
                 feel-obligated
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

;;;****************
;;;* WHAT TO DRINK *
;;;****************
(defrule highball-conclusion ""
   (declare (salience 10))
   (or
   (major-celebration no)
   (feel-obligated yes)
   )
   =>
   (handle-state conclusion  "Highball"))
(defrule beer-conclusion ""
    (declare (salience 10))
    (write-off no)
    =>
    (handle-state conclusion  "Beer"))

(defrule lowball-conclusion ""
    (declare (salience 10))
    (write-off yes)
    =>
    (handle-state conclusion  "Lowball"))
(defrule cocktail-conclusion ""
    (declare (salience 10))
    (or
    (expense-big no)
    (like-people no)
    (feel-obligated no)
    )

    =>
    (handle-state conclusion  "Fancy cocktail"))

(defrule wine-conclusion ""
   (declare (salience 10))
   (or (take-to-dinner no)
   (mormon no)
   (get-wasted no))
   =>
   (handle-state conclusion  "Wine"))

(defrule martini-conclusion ""
   (declare (salience 10))
   (or (friday-night yes)
       (take-to-dinner yes)
       (planning-work no))
   =>
   (handle-state conclusion  "Martini"))

(defrule bubbly-conclusion ""
   (declare (salience 10))
   (or (like-person yes)
   (planning-work yes))
   =>
   (handle-state conclusion  "Bubbly"))
(defrule non-alcoholic-conclusion ""
    (declare (salience 10))
    (mormon yes)
    =>
    (handle-state conclusion  "Non-alcoholic"))
