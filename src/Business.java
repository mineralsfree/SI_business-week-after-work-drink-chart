import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

import java.text.BreakIterator;

import java.util.Locale;
import java.util.ResourceBundle;
import java.util.MissingResourceException;

import java.util.ArrayList;

import net.sf.clipsrules.jni.*;

/* Implement FindFact which returns just a FactAddressValue or null */
/* TBD Add size method to PrimitiveValue */

/*

Notes:

This example creates just a single environment. If you create multiple environments,
call the destroy method when you no longer need the environment. This will free the
C data structures associated with the environment.

   clips = new Environment();
      .
      . 
      .
   clips.destroy();

Calling the clear, reset, load, loadFacts, run, eval, build, assertString,
and makeInstance methods can trigger CLIPS garbage collection. If you need
to retain access to a PrimitiveValue returned by a prior eval, assertString,
or makeInstance call, retain it and then release it after the call is made.

   PrimitiveValue pv1 = clips.eval("(myFunction foo)");
   pv1.retain();
   PrimitiveValue pv2 = clips.eval("(myFunction bar)");
      .
      .
      .
   pv1.release();

*/

class Business implements ActionListener {
    private enum InterviewState {
        GREETING,
        INTERVIEW,
        CONCLUSION
    }

    ;

    JLabel displayLabel;
    JButton nextButton;
    JButton prevButton;
    JPanel choicesPanel;
    ButtonGroup choicesButtons;
    ResourceBundle businessResources;

    Environment clips;
    boolean isExecuting = false;
    Thread executionThread;

    String lastAnswer;
    String relationAsserted;
    ArrayList<String> variableAsserts;
    ArrayList<String> priorAnswers;

    InterviewState interviewState;

    Business() {
        try {
            businessResources = ResourceBundle.getBundle("resources.businessResources", Locale.getDefault());
        } catch (MissingResourceException mre) {
            mre.printStackTrace();
            return;
        }
        JFrame jfrm = new JFrame(businessResources.getString("BUSINESS"));
        jfrm.getContentPane().setLayout(new GridLayout(3, 1));
        jfrm.setSize(350, 200);
        jfrm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        JPanel displayPanel = new JPanel();
        displayLabel = new JLabel();
        displayPanel.add(displayLabel);
        choicesPanel = new JPanel();
        choicesButtons = new ButtonGroup();
        JPanel buttonPanel = new JPanel();

        prevButton = new JButton(businessResources.getString("Prev"));
        prevButton.setActionCommand("Prev");
        buttonPanel.add(prevButton);
        prevButton.addActionListener(this);

        nextButton = new JButton(businessResources.getString("Next"));
        nextButton.setActionCommand("Next");
        buttonPanel.add(nextButton);
        nextButton.addActionListener(this);

        jfrm.getContentPane().add(displayPanel);
        jfrm.getContentPane().add(choicesPanel);
        jfrm.getContentPane().add(buttonPanel);

        variableAsserts = new ArrayList<>();
        priorAnswers = new ArrayList<>();

        clips = new Environment();
        clips.loadFromResource("resources/business.clp");
        clips.loadFromResource("resources/business_en.clp" );

        processRules();
        jfrm.setVisible(true);
//        clips.eval("(set-strategy random)");

    }


    private void handleResponse() throws Exception {

        String evalStr = "(find-fact ((?f UI-state)) TRUE)";

        FactAddressValue fv = (FactAddressValue) ((MultifieldValue) clips.eval(evalStr)).get(0);

        if (fv.getFactSlot("state").toString().equals("conclusion")) {
            interviewState = InterviewState.CONCLUSION;
            nextButton.setActionCommand("Restart");
            nextButton.setText(businessResources.getString("Restart"));
            prevButton.setVisible(true);
            choicesPanel.setVisible(false);
        } else if (fv.getFactSlot("state").toString().equals("greeting")) {
            interviewState = InterviewState.GREETING;
            nextButton.setActionCommand("Next");
            nextButton.setText(businessResources.getString("Next"));
            prevButton.setVisible(false);
            choicesPanel.setVisible(false);
        } else {
            interviewState = InterviewState.INTERVIEW;
            nextButton.setActionCommand("Next");
            nextButton.setText(businessResources.getString("Next"));
            prevButton.setVisible(true);
            choicesPanel.setVisible(true);
        }

        choicesPanel.removeAll();
        choicesButtons = new ButtonGroup();

        MultifieldValue damf = (MultifieldValue) fv.getFactSlot("display-answers");
        MultifieldValue vamf = (MultifieldValue) fv.getFactSlot("valid-answers");

        String selected = fv.getFactSlot("response").toString();
        JRadioButton firstButton = null;

        for (int i = 0; i < damf.size(); i++) {
            LexemeValue da = (LexemeValue) damf.get(i);
            LexemeValue va = (LexemeValue) vamf.get(i);
            JRadioButton rButton;
            String buttonName, buttonText, buttonAnswer;

            buttonName = da.lexemeValue();
            buttonText = buttonName.substring(0, 1).toUpperCase() + buttonName.substring(1);
            buttonAnswer = va.lexemeValue();
            if ((buttonAnswer.equals(lastAnswer)) ||
                    ((lastAnswer == null) && buttonAnswer.equals(selected))) {
                rButton = new JRadioButton(buttonText, true);
            } else {
                rButton = new JRadioButton(buttonText, false);
            }

            rButton.setActionCommand(buttonAnswer);
            choicesPanel.add(rButton);
            choicesButtons.add(rButton);

            if (firstButton == null) {
                firstButton = rButton;
            }
        }

        if ((choicesButtons.getSelection() == null) && (firstButton != null)) {
            choicesButtons.setSelected(firstButton.getModel(), true);
        }

        choicesPanel.repaint();

        /*====================================*/
        /* Set the label to the display text. */
        /*====================================*/

        relationAsserted = ((LexemeValue) fv.getFactSlot("relation-asserted")).lexemeValue();

        /*====================================*/
        /* Set the label to the display text. */
        /*====================================*/

        String theText = ((StringValue) fv.getFactSlot("display")).stringValue();

        wrapLabelText(displayLabel, theText);

        executionThread = null;

        isExecuting = false;
    }

    /*########################*/
    /* ActionListener Methods */
    /*########################*/

    /*******************/
    /* actionPerformed */

    /*******************/
    public void actionPerformed(
            ActionEvent ae) {
        try {
            onActionPerformed(ae);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /***********/
    /* runAuto */

    /***********/
    public void runAuto() {
        Runnable runThread =
                () -> {
                    clips.run();

                    SwingUtilities.invokeLater(
                            () -> {
                                try {
                                    handleResponse();
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                            });
                };

        isExecuting = true;

        executionThread = new Thread(runThread);

        executionThread.start();
    }

    /****************/
    /* processRules */

    /****************/
    private void processRules() {
        clips.reset();

        for (String factString : variableAsserts) {
            String assertCommand = "(assert " + factString + ")";
            clips.eval(assertCommand);
        }

        runAuto();
    }

    private void nextButtonAction() {
        String theString;
        String theAnswer;

        lastAnswer = null;
        switch (interviewState) {
            /* Handle Next button. */
            case GREETING:
            case INTERVIEW:
                theAnswer = choicesButtons.getSelection().getActionCommand();
                theString = "(" + relationAsserted + " " + theAnswer + ")";
                variableAsserts.add(theString);
                priorAnswers.add(theAnswer);
                break;

            /* Handle Restart button. */
            case CONCLUSION:
                variableAsserts.clear();
                priorAnswers.clear();
                break;
        }

        processRules();
    }

    private void prevButtonAction() {
        lastAnswer = priorAnswers.get(priorAnswers.size() - 1);

        variableAsserts.remove(variableAsserts.size() - 1);
        priorAnswers.remove(priorAnswers.size() - 1);

        processRules();
    }

    private void onActionPerformed(
            ActionEvent ae) throws Exception {
        if (isExecuting) return;

        if (ae.getActionCommand().equals("Next")) {
            nextButtonAction();
        } else if (ae.getActionCommand().equals("Restart")) {
            nextButtonAction();
        } else if (ae.getActionCommand().equals("Prev")) {
            prevButtonAction();
        }
    }

    private void wrapLabelText(
            JLabel label,
            String text) {
        FontMetrics fm = label.getFontMetrics(label.getFont());
        Container container = label.getParent();
        int containerWidth = container.getWidth();
        int textWidth = SwingUtilities.computeStringWidth(fm, text);
        int desiredWidth;

        if (textWidth <= containerWidth) {
            desiredWidth = containerWidth;
        } else {
            int lines = (int) ((textWidth + containerWidth) / containerWidth);

            desiredWidth = (int) (textWidth / lines);
        }

        BreakIterator boundary = BreakIterator.getWordInstance();
        boundary.setText(text);

        StringBuffer trial = new StringBuffer();
        StringBuffer real = new StringBuffer("<html><center>");

        int start = boundary.first();
        for (int end = boundary.next(); end != BreakIterator.DONE;
             start = end, end = boundary.next()) {
            String word = text.substring(start, end);
            trial.append(word);
            int trialWidth = SwingUtilities.computeStringWidth(fm, trial.toString());
            if (trialWidth > containerWidth) {
                trial = new StringBuffer(word);
                real.append("<br>");
                real.append(word);
            } else if (trialWidth > desiredWidth) {
                trial = new StringBuffer("");
                real.append(word);
                real.append("<br>");
            } else {
                real.append(word);
            }
        }

        real.append("</html>");

        label.setText(real.toString());
    }

    public static void main(String args[]) {
        // Create the frame on the event dispatching thread.
        SwingUtilities.invokeLater(Business::new);
    }
}
