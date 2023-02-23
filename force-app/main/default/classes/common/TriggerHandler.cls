public virtual class TriggerHandler {
    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    @TestVisible
    private static String topHandlerName;

    @TestVisible
    private static Map<String, Boolean> runOnce;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
        runOnce = new Map<String, Boolean>();
    }

    /* Static methods */
    // FKR: extension for recursion management
    public static Boolean checkRunOnce(String handlerAndMethodName) {
        if (null == runOnce.get(handlerAndMethodName)) {
            runOnce.put(handlerAndMethodName, false);
            return true;
        }

        return false;
    }

    // constructor
    public TriggerHandler() {
        this.setTriggerContext();
        if (null == TriggerHandler.topHandlerName) {
            TriggerHandler.topHandlerName = getHandlerName();
        }
    }

    // ---------------------------------------------------------------------------
    // Instance Methods
    // ---------------------------------------------------------------------------

    // main method that will be called during execution
    public void run() {
        if (!validateRun()) {
            return;
        }

        addToLoopCount();

        // dispatch to the correct handler method
        if (this.context == TriggerContext.BEFORE_INSERT) {
            this.beforeInsert();
        } else if (this.context == TriggerContext.BEFORE_UPDATE) {
            this.beforeUpdate();
        } else if (this.context == TriggerContext.BEFORE_DELETE) {
            this.beforeDelete();
        } else if (this.context == TriggerContext.AFTER_INSERT) {
            this.afterInsert();
        } else if (this.context == TriggerContext.AFTER_UPDATE) {
            this.afterUpdate();
        } else if (this.context == TriggerContext.AFTER_DELETE) {
            this.afterDelete();
        } else if (this.context == TriggerContext.AFTER_UNDELETE) {
            this.afterUndelete();
        }
    }

    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();

        if (!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    // FKR: method to invoke the control of method executions.
    public Boolean canRunOnce(String methodName) {
        return checkRunOnce(getHandlerName() + '.' + methodName);
    }

    // ---------------------------------------------------------------------------
    // Static Methods
    // ---------------------------------------------------------------------------

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

    // FKR: extension for recursion management
    public static String getTopHandlerName() {
        return topHandlerName;
    }

    // FKR: method to reset the control of method executions.
    public static void resetRun() {
        runOnce = new Map<String, Boolean>();
    }

    // ---------------------------------------------------------------------------
    // Private Instance Methods / Helpers
    // ---------------------------------------------------------------------------

    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext(TriggerContextOverride contextOverride, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if (
            (Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.BEFORE_INSERT)
        ) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if (
            (Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.BEFORE_UPDATE)
        ) {
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if (
            (Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.BEFORE_DELETE)
        ) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.AFTER_INSERT)
        ) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.AFTER_UPDATE)
        ) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.AFTER_DELETE)
        ) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if (
            (Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
            (contextOverride != null &&
            contextOverride == TriggerContextOverride.AFTER_UNDELETE)
        ) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();

        if (TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();

            if (exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException(
                    'Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName
                );
            }
        }
    }

    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException(
                'Trigger handler called outside of Trigger execution'
            );
        }

        if (TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            System.debug(
                'TriggerHandler.validateRun() - Bypass Trigger Handler "' + getHandlerName() + '"'
            );
            return false;
        }

        return true;
    }

    @TestVisible
    protected String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }

    // ---------------------------------------------------------------------------
    // Context Methods
    // ---------------------------------------------------------------------------

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert() {
    }

    @TestVisible
    protected virtual void beforeUpdate() {
    }

    @TestVisible
    protected virtual void beforeDelete() {
    }

    @TestVisible
    protected virtual void afterInsert() {
    }

    @TestVisible
    protected virtual void afterUpdate() {
    }

    @TestVisible
    protected virtual void afterDelete() {
    }

    @TestVisible
    protected virtual void afterUndelete() {
    }

    // ---------------------------------------------------------------------------
    // Inner Classes
    // ---------------------------------------------------------------------------

    // inner class for managing the loop count per handler
    @TestVisible
    private with sharing class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if (this.max < 0) {
                return false;
            }

            if (this.count > this.max) {
                return true;
            }

            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }

    @TestVisible
    private enum TriggerContextOverride {
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
    }

    // exception class
    public with sharing class TriggerHandlerException extends Exception {
    }
}
