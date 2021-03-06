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
    (not (like-people ?))
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
    (or (close-deal no)
    (like-person no))
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
(defrule determine-have-life ""
    (stay-radar no)
    (not (have-life ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Do you have a life?"
                 have-life
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

;;;* BOSS *

(defrule determine-did-he-ask""
   (drink-with boss)
   (not (did-he-ask ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Did he or she ask you to drinks?"
                 did-he-ask
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-celebrating-sth ""
    (did-he-ask yes)
    (not (celebrating-sth  ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you celebrating something?"
                 celebrating-sth
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-ask-for-raise ""
    (did-he-ask no)
    (not (ask-for-raise  ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you asking for a raise?"
                 ask-for-raise
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-in-trouble ""
    (celebrating-sth no)
    (not (in-trouble  ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you worried you're in trouble?"
                 in-trouble
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-trying-sleep ""
    (or (in-trouble no)
    (trying-seduce no))
    (not (trying-sleep  ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is he or she trying to sleep with you?"
                 trying-sleep
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-talk-back ""
    (in-trouble yes)
    (not (talk-back  ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Will you talk back?"
                 talk-back
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-just-promotion ""
    (ask-for-raise no)
    (not (just-promotion ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Just a promotion?"
                 just-promotion
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-trying-seduce ""
    (just-promotion no)
    (not (trying-seduce ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you trying to seduce your boss?"
                 trying-seduce
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-good-idea ""
    (trying-seduce yes)
    (not (good-idea ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you sure this is a good idea?"
                 good-idea
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

;;;* COLLEAGUE *

(defrule determine-why-college ""
   (drink-with college)
   (not (why-college ?))
   =>
   (bind ?answers (create$ gripe-work ask-advice give-advice))
   (handle-state interview
                 "Why?"
                 why-college
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-work-drinks ""
    (why-college gripe-work)
    (not (work-drinks ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Can this be expensed as work drinks?"
                 work-drinks
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-companion-male ""
    (work-drinks yes)
    (not (companion-male ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is your companion male?"
                 companion-male
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-girls-night ""
    (companion-male no)
    (not (girls-night ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is this is girls' night?"
                 girls-night
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-get-fired ""
    (why-college ask-advice)
    (not (get-fired ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Are you about to get fired?"
                 get-fired
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-scheming-promotion ""
    (get-fired no)
    (not (scheming-promotion ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Just scheming for a promotion?"
                 scheming-promotion
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-can-help ""
    (scheming-promotion yes)
    (not (can-help ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Can this person help you?"
                 can-help
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-morph-bitchfest ""
    (or (scheming-promotion no)
    (can-help no))
    (not (morph-bitchfest ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Will this morph into a bitchfest?"
                 morph-bitchfest
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-invite-out ""
    (why-college give-advice)
    (not (invite-out ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Did he or she invite you out?"
                 invite-out
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-performance-warning ""
    (invite-out no)
    (not (performance-warning ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is this a performance warning?"
                 performance-warning
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-handle-truth ""
    (invite-out yes)
    (not (handle-truth ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Can this person handle the truth?"
                 handle-truth
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-is-crier ""
    (or (performance-warning yes)
    (handle-truth no))
    (not (is-crier ?))
   =>
   (bind ?answers (create$ no yes))
   (handle-state interview
                 "Is he or she a crier?"
                 is-crier
                 (nth$ 1 ?answers)
                 ?answers
                 (translate-av ?answers)))

(defrule determine-being-honest ""
    (have-life yes)
    (not (being-honest ?))
   =>
   (bind ?answers (create$ ok))
   (handle-state interview
                 "You aren't being honest. Try again"
                 being-honest
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
   (morph-bitchfest no)
   )
   =>
   (handle-state conclusion  "Highball"))
(defrule beer-conclusion ""
    (declare (salience 10))
    (or (write-off no)
    (work-drinks no)
    (girls-night no)
    (morph-bitchfest yes))
    =>
    (handle-state conclusion  "Beer"))

(defrule lowball-conclusion ""
    (declare (salience 10))
    (or
    (write-off yes)
    (companion-male yes)
    (performance-warning no))
    =>
    (handle-state conclusion  "Lowball"))
(defrule cocktail-conclusion ""
    (declare (salience 10))
    (or
    (expense-big no)
    (like-people no)
    (feel-obligated no)
    (good-idea yes)
    (girls-night yes)
    (is-crier no)
    )

    =>
    (handle-state conclusion  "Fancy cocktail"))

(defrule wine-conclusion ""
   (declare (salience 10))
   (or (take-to-dinner no)
   (mormon no)
   (get-wasted no)
   (trying-sleep no)
   (talk-back no)
   (handle-truth yes)
   (can-help yes))
   =>
   (handle-state conclusion  "Wine"))

(defrule martini-conclusion ""
   (declare (salience 10))
   (or (friday-night yes)
       (take-to-dinner yes)
       (planning-work no)
       (good-idea no)
       (is-crier yes)
       (get-fired yes))
   =>
   (handle-state conclusion  "Martini"))

(defrule bubbly-conclusion ""
   (declare (salience 10))
   (or (like-person yes)
   (planning-work yes)
   (celebrating-sth yes))
   =>
   (handle-state conclusion  "Bubbly"))
(defrule non-alcoholic-conclusion ""
    (declare (salience 10))
    (or (mormon yes)
    (talk-back yes)
    (trying-sleep yes))
    =>
    (handle-state conclusion  "Non-alcoholic"))
(defrule do-office-conclusion ""
    (declare (salience 10))
    (or (ask-for-raise yes)
    (just-promotion yes))
    =>
    (handle-state conclusion  "STOP! Do this in the office"))
(defrule get-life-conclusion ""
    (declare (salience 10))
    (or (being-honest ok)
    (have-life no))
    =>
    (handle-state conclusion  "STOP! Get a life"))
