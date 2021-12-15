package net.sf.clipsrules.jni;

public class InstanceAddressValue extends InstanceValue
  {
   private net.sf.clipsrules.jni.Environment owner;

   /*************************/
   /* InstanceAddressValue: */
   /*************************/
   public InstanceAddressValue(
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
     
   /***********************/
   /* getInstanceAddress: */
   /***********************/     
   public long getInstanceAddress()
     { return ((Long) getValue()).longValue(); }

   /******************/
   /* directGetSlot: */
   /******************/     
   public PrimitiveValue directGetSlot(
     String slotName)
     { return net.sf.clipsrules.jni.Environment.directGetSlot(this,slotName); }

   /********************/
   /* getInstanceName: */
   /********************/     
   public String getInstanceName()
     { return Environment.getInstanceName(this); }
     
   /*************/
   /* toString: */
   /*************/
   @Override
   public String toString()
     {        
      return "<Instance-" + getInstanceName() + ">";
     }

   /***********/
   /* retain: */
   /***********/
   @Override
   public void retain()
     {
      owner.incrementInstanceCount(this);
     }

   /************/
   /* release: */
   /************/
   @Override
   public void release()
     {
      owner.decrementInstanceCount(this);
     }
  }
