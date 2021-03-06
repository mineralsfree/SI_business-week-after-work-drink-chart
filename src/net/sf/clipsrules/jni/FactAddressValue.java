package net.sf.clipsrules.jni;

public class FactAddressValue extends PrimitiveValue
  {
   private net.sf.clipsrules.jni.Environment owner;

   /*********************/
   /* FactAddressValue: */
   /*********************/
   public FactAddressValue(
     long value,
     net.sf.clipsrules.jni.Environment env)
     {
      super(new Long(value));
      
      owner = env;
     }

   /*******************/
   /* getEnvironment: */
   /*******************/
   public net.sf.clipsrules.jni.Environment getEnvironment()
     { return owner; }
     
   /*******************/
   /* getFactAddress: */
   /*******************/     
   public long getFactAddress()
     { return ((Long) getValue()).longValue(); }

   /****************/
   /* getFactSlot: */
   /****************/     
   public PrimitiveValue getFactSlot(
     String slotName) throws Exception
     { return net.sf.clipsrules.jni.Environment.getFactSlot(this,slotName); }

   /*****************/
   /* getFactIndex: */
   /*****************/     
   public long getFactIndex()
     { return Environment.factIndex(this); }

   /***********/
   /* retain: */
   /***********/
   @Override
   public void retain()
     {
      owner.incrementFactCount(this);
     }

   /************/
   /* release: */
   /************/
   @Override
   public void release()
     {
      owner.decrementFactCount(this);
     }
     
   /*************/
   /* toString: */
   /*************/
   @Override
   public String toString()
     {        
      return "<Fact-" + getFactIndex() + ">";
     }
  }
