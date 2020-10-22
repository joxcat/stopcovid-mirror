package test.fr.gouv.stopc.robertserver.batch.processor;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.server.batch.processor.UpdateRegistrationFlagsProcessor;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.database.model.Registration;

@ExtendWith(SpringExtension.class)
@TestPropertySource("classpath:application.properties")
public class UpdateRegistrationFlagsProcessorTest {

    private static final String SHOULD_NOT_FAIL = "It should not fail";

    @Mock
    private PropertyLoader propertyLoader;

    @Value("${robert.at-risk.notification.epoch.minimum-gap}")
    private Integer atRiskNotificationEpochGap;

    private UpdateRegistrationFlagsProcessor processor;

    @BeforeEach
    public void beforeEach() {
        this.processor = new UpdateRegistrationFlagsProcessor(this.propertyLoader);
        when(this.propertyLoader.getAtRiskNotificationEpochGap()).thenReturn(this.atRiskNotificationEpochGap);
    }

    @Test
    public void testRegistrationShouldNotBeUpdatedWhenNotAtRiskAndNotNotified() {

        try {
            // Given
            Registration registration = Registration.builder()
                    .atRisk(false)
                    .isNotified(false)
                    .build();

            // When
            Registration processedRegistration =  this.processor.process(registration);

            // Then
            assertNull(processedRegistration);
        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testRegistrationShouldNotBeUpdatedWhenNotAtRiskAndNotified() {

        try {
            // Given
            Registration registration = Registration.builder()
                    .atRisk(false)
                    .isNotified(true)
                    .build();

            // When
            Registration processedRegistration =  this.processor.process(registration);

            // Then
            assertNull(processedRegistration);
        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testRegistrationShouldNotBeUpdatedWhenAtRiskAndNotNotified() {

        try {
            // Given
            Registration registration = Registration.builder()
                    .atRisk(true)
                    .isNotified(false)
                    .build();

            // When
            Registration processedRegistration =  this.processor.process(registration);

            // Then
            assertNull(processedRegistration);
        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testRegistrationShouldNotBeUpdatedWhenAtRiskAndNotifiedButEpochMinimunIsNotReached() {

        try {
            // Given
            Registration registration = Registration.builder()
                    .atRisk(true)
                    .isNotified(true)
                    .lastStatusRequestEpoch(5000)
                    .latestRiskEpoch(4912)
                    .build();

            // When
            Registration processedRegistration =  this.processor.process(registration);

            // Then
            assertNull(processedRegistration);
        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testRegistrationShouldNotBeUpdatedWhenAtRiskAndNotifiedButEpochMinimunIsReached() {

        try {
            // Given
            Registration registration = Registration.builder()
                    .atRisk(true)
                    .isNotified(true)
                    .lastStatusRequestEpoch(5000)
                    .latestRiskEpoch(4808)
                    .build();

            // When
            Registration processedRegistration =  this.processor.process(registration);

            // Then
            assertNotNull(processedRegistration);
            assertFalse(processedRegistration.isAtRisk());
            assertTrue(processedRegistration.isNotified());
        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testRegistrationShouldNotBeUpdatedWhenAtRiskAndNotifiedButEpochMinimunIsExceeded() {

        try {
            // Given
            Registration registration = Registration.builder()
                    .atRisk(true)
                    .isNotified(true)
                    .lastStatusRequestEpoch(5000)
                    .latestRiskEpoch(4500)
                    .build();

            // When
            Registration processedRegistration =  this.processor.process(registration);

            // Then
            assertNotNull(processedRegistration);
            assertFalse(processedRegistration.isAtRisk());
            assertTrue(processedRegistration.isNotified());
        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }
}
