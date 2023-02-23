@IsTest(IsParallel=true)
private with sharing class TriggerHandler_Test {
    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';

    private static String lastMethodCalled;

    private static TriggerHandler_Test.TestHandler handler;

    static {
        handler = new TriggerHandler_Test.TestHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
    }

    // ---------------------------------------------------------------------------
    // Utility Tests
    // ---------------------------------------------------------------------------

    @isTest
    static void testTopHandler() {
        beforeInsertMode();

        handler.run();

        System.assertEquals(
            'TestHandler',
            TriggerHandler.getTopHandlerName(),
            'top handler should be TestHandler'
        );
    }

    @isTest
    static void testResetRun() {
        final String METHOD_TO_RUN_ONCE = 'beforeInsert';

        handler.canRunOnce(METHOD_TO_RUN_ONCE);

        beforeInsertMode();

        handler.run();

        System.assertEquals(
            false,
            TriggerHandler.checkRunOnce('TestHandler.' + METHOD_TO_RUN_ONCE),
            'Should have marked method already ran once'
        );

        System.assertEquals(
            false,
            handler.canRunOnce(METHOD_TO_RUN_ONCE),
            'Should have marked method already ran once'
        );

        TriggerHandler.resetRun();

        System.assert(handler.canRunOnce(METHOD_TO_RUN_ONCE), 'Should have reset run once marker');
    }

    // ---------------------------------------------------------------------------
    // Context Tests
    // ---------------------------------------------------------------------------

    @isTest
    static void testBeforeInsert() {
        beforeInsertMode();

        handler.run();

        System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
    }

    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();

        handler.run();

        System.assertEquals('beforeUpdate', lastMethodCalled, 'last method should be beforeUpdate');
    }

    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();

        handler.run();

        System.assertEquals('beforeDelete', lastMethodCalled, 'last method should be beforeDelete');
    }

    @isTest
    static void testAfterInsert() {
        afterInsertMode();

        handler.run();

        System.assertEquals('afterInsert', lastMethodCalled, 'last method should be afterInsert');
    }

    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();

        handler.run();

        System.assertEquals('afterUpdate', lastMethodCalled, 'last method should be afterUpdate');
    }

    @isTest
    static void testAfterDelete() {
        afterDeleteMode();

        handler.run();

        System.assertEquals('afterDelete', lastMethodCalled, 'last method should be afterDelete');
    }

    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();

        handler.run();

        System.assertEquals(
            'afterUndelete',
            lastMethodCalled,
            'last method should be afterUndelete'
        );
    }

    @isTest
    static void testNonTriggerContext() {
        try {
            handler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch (TriggerHandler.TriggerHandlerException te) {
            System.assertEquals(
                TRIGGER_CONTEXT_ERROR,
                te.getMessage(),
                'the exception message should match'
            );
        } catch (Exception e) {
            System.assert(
                false,
                'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage()
            );
        }
    }

    // ---------------------------------------------------------------------------
    // bypass API Tests
    // ---------------------------------------------------------------------------

    @isTest
    static void testBypassApi() {
        afterUpdateMode();

        // test a bypass and run handler
        TriggerHandler.bypass('TestHandler');

        handler.run();

        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');

        System.assertEquals(
            true,
            TriggerHandler.isBypassed('TestHandler'),
            'test handler should be bypassed'
        );
        resetTest();

        // clear that bypass and run handler
        TriggerHandler.clearBypass('TestHandler');

        handler.run();

        System.assertEquals(
            'afterUpdate',
            lastMethodCalled,
            'last method called should be afterUpdate'
        );
        System.assertEquals(
            false,
            TriggerHandler.isBypassed('TestHandler'),
            'test handler should be bypassed'
        );
        resetTest();

        // test a re-bypass and run handler
        TriggerHandler.bypass('TestHandler');

        handler.run();

        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');

        System.assertEquals(
            true,
            TriggerHandler.isBypassed('TestHandler'),
            'test handler should be bypassed'
        );
        resetTest();

        // clear all bypasses and run handler
        TriggerHandler.clearAllBypasses();

        handler.run();

        System.assertEquals(
            'afterUpdate',
            lastMethodCalled,
            'last method called should be afterUpdate'
        );
        System.assertEquals(
            false,
            TriggerHandler.isBypassed('TestHandler'),
            'test handler should be bypassed'
        );

        resetTest();
    }

    // ---------------------------------------------------------------------------
    // Instace Method Tests
    // ---------------------------------------------------------------------------

    @isTest
    static void testLoopCount() {
        beforeInsertMode();

        // set the max loops to 2
        handler.setMaxLoopCount(2);

        // run the handler twice
        handler.run();
        handler.run();

        // clear the tests
        resetTest();

        try {
            // try running it. This should exceed the limit.
            handler.run();
            System.assert(false, 'the handler should throw on the 3rd run when maxloopcount is 3');
        } catch (TriggerHandler.TriggerHandlerException te) {
            // we're expecting to get here
            System.assertEquals(null, lastMethodCalled, 'last method should be null');
        } catch (Exception e) {
            System.assert(
                false,
                'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage()
            );
        }

        // clear the tests
        resetTest();

        // now clear the loop count
        handler.clearMaxLoopCount();

        try {
            // re-run the handler. We shouldn't throw now.
            handler.run();
            System.assertEquals(
                'beforeInsert',
                lastMethodCalled,
                'last method should be beforeInsert'
            );
        } catch (TriggerHandler.TriggerHandlerException te) {
            System.assert(
                false,
                'running the handler after clearing the loop count should not throw'
            );
        } catch (Exception e) {
            System.assert(
                false,
                'the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage()
            );
        }
    }

    @isTest
    static void testLoopCountClass() {
        TriggerHandler.LoopCount loopCount = new TriggerHandler.LoopCount();

        System.assertEquals(5, loopCount.getMax(), 'max should be five on init');
        System.assertEquals(0, loopCount.getCount(), 'count should be zero on init');

        loopCount.increment();
        System.assertEquals(1, loopCount.getCount(), 'count should be 1');
        System.assertEquals(false, loopCount.exceeded(), 'should not be exceeded with count of 1');

        loopCount.increment();
        loopCount.increment();
        loopCount.increment();
        loopCount.increment();
        System.assertEquals(5, loopCount.getCount(), 'count should be 5');
        System.assertEquals(false, loopCount.exceeded(), 'should not be exceeded with count of 5');

        loopCount.increment();
        System.assertEquals(6, loopCount.getCount(), 'count should be 6');
        System.assertEquals(true, loopCount.exceeded(), 'should not be exceeded with count of 6');
    }

    // ---------------------------------------------------------------------------
    // Private Method Tests
    // ---------------------------------------------------------------------------

    @isTest
    static void testGetHandlerName() {
        System.assertEquals(
            'TestHandler',
            handler.getHandlerName(),
            'handler name should match class name'
        );
    }

    // ---------------------------------------------------------------------------
    // Test Virtual Methods
    // ---------------------------------------------------------------------------

    @isTest
    static void testVirtualMethods() {
        TriggerHandler handler = new TriggerHandler();

        handler.beforeInsert();
        handler.beforeUpdate();
        handler.beforeDelete();
        handler.afterInsert();
        handler.afterUpdate();
        handler.afterDelete();
        handler.afterUndelete();

        System.assertNotEquals(null, handler);
    }

    // ---------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------

    private static void resetTest() {
        lastMethodCalled = null;
    }

    // ---------------------------------------------------------------------------
    // Modes for Testing
    // ---------------------------------------------------------------------------

    private static void beforeInsertMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.BEFORE_INSERT, true);
    }

    private static void beforeUpdateMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.BEFORE_UPDATE, true);
    }

    private static void beforeDeleteMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.BEFORE_DELETE, true);
    }

    private static void afterInsertMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.AFTER_INSERT, true);
    }

    private static void afterUpdateMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.AFTER_UPDATE, true);
    }

    private static void afterDeleteMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.AFTER_DELETE, true);
    }

    private static void afterUndeleteMode() {
        handler.setTriggerContext(TriggerHandler.TriggerContextOverride.AFTER_UNDELETE, true);
    }

    // ---------------------------------------------------------------------------
    // "Mock" Implementation of the TriggerHandler
    // ---------------------------------------------------------------------------

    private with sharing class TestHandler extends TriggerHandler {
        public override void beforeInsert() {
            TriggerHandler_Test.lastMethodCalled = 'beforeInsert';
        }

        public override void beforeUpdate() {
            TriggerHandler_Test.lastMethodCalled = 'beforeUpdate';
        }

        public override void beforeDelete() {
            TriggerHandler_Test.lastMethodCalled = 'beforeDelete';
        }

        public override void afterInsert() {
            TriggerHandler_Test.lastMethodCalled = 'afterInsert';
        }

        public override void afterUpdate() {
            TriggerHandler_Test.lastMethodCalled = 'afterUpdate';
        }

        public override void afterDelete() {
            TriggerHandler_Test.lastMethodCalled = 'afterDelete';
        }

        public override void afterUndelete() {
            TriggerHandler_Test.lastMethodCalled = 'afterUndelete';
        }
    }
}
