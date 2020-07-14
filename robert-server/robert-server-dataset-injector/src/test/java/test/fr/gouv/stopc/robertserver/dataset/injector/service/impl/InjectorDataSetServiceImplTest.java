package test.fr.gouv.stopc.robertserver.dataset.injector.service.impl;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.database.model.ClientIdentifier;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.database.repository.ClientIdentifierRepository;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import fr.gouv.stopc.robertserver.dataset.injector.RobertServerInjectorDatasetApplication;
import fr.gouv.stopc.robertserver.dataset.injector.service.GeneratorIdService;
import fr.gouv.stopc.robertserver.dataset.injector.service.InjectorDataSetService;
import lombok.extern.slf4j.Slf4j;
import org.bson.internal.Base64;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import test.fr.gouv.stopc.robertserver.dataset.injector.utils.GenerateIdUtils;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@Slf4j
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = {RobertServerInjectorDatasetApplication.class })
@TestPropertySource("classpath:application.properties")
public class InjectorDataSetServiceImplTest {

    @MockBean
    private GeneratorIdService generatorIdService;

    @MockBean
    private ClientIdentifierRepository clientIdentifierRepository;

    @Autowired
    private InjectorDataSetService injectorDataSetService;

    @Autowired
    private ContactService contactService;

    @Autowired
    private RegistrationService registrationService;

    @Test
    public void testInjectContactsSuccess() {
        // Mock call services
        byte[] idA1 = GenerateIdUtils.generateIdA();
        byte[] idA2 = GenerateIdUtils.generateIdA();
        byte[] idA3 = GenerateIdUtils.generateIdA();
        byte[] idA4 = GenerateIdUtils.generateIdA();
        byte[] idA5 = GenerateIdUtils.generateIdA();

        byte[] keyMac1 = GenerateIdUtils.getKeyMacFor(idA1);
        byte[] keyMac2 = GenerateIdUtils.getKeyMacFor(idA2);
        byte[] keyMac3 = GenerateIdUtils.getKeyMacFor(idA3);
        byte[] keyMac4 = GenerateIdUtils.getKeyMacFor(idA4);
        byte[] keyMac5 = GenerateIdUtils.getKeyMacFor(idA5);

        when(generatorIdService.generateIdA())
                .thenReturn(idA1)
                .thenReturn(idA2)
                .thenReturn(idA3)
                .thenReturn(idA4)
                .thenReturn(idA5);
        when(generatorIdService.decryptStoredKeyWithAES256GCMAndKek(any(), any()))
                .thenReturn(GenerateIdUtils.generateRandomKey())
                .thenReturn(GenerateIdUtils.generateRandomKey())
                .thenReturn(GenerateIdUtils.generateRandomKey())
                .thenReturn(GenerateIdUtils.generateRandomKey())
                .thenReturn(GenerateIdUtils.generateRandomKey());
        when(clientIdentifierRepository.findByIdA(any()))
                .thenReturn(Optional.of(
                        ClientIdentifier.builder()
                                .idA(Base64.encode(idA1))
                                .keyForMac(Base64.encode(keyMac1))
                                .keyForTuples(Base64.encode(GenerateIdUtils.generateRandomKey()))
                                .build()))
                .thenReturn(Optional.of(
                        ClientIdentifier.builder()
                                .idA(Base64.encode(idA2))
                                .keyForMac(Base64.encode(keyMac2))
                                .keyForTuples(Base64.encode(GenerateIdUtils.generateRandomKey()))
                                .build()))
                .thenReturn(Optional.of(
                        ClientIdentifier.builder()
                                .idA(Base64.encode(idA3))
                                .keyForMac(Base64.encode(keyMac3))
                                .keyForTuples(Base64.encode(GenerateIdUtils.generateRandomKey()))
                                .build()))
                .thenReturn(Optional.of(
                        ClientIdentifier.builder()
                                .idA(Base64.encode(idA4))
                                .keyForMac(Base64.encode(keyMac4))
                                .keyForTuples(Base64.encode(GenerateIdUtils.generateRandomKey()))
                                .build()))
                .thenReturn(Optional.of(
                        ClientIdentifier.builder()
                                .idA(Base64.encode(idA5))
                                .keyForMac(Base64.encode(keyMac5))
                                .keyForTuples(Base64.encode(GenerateIdUtils.generateRandomKey()))
                                .build()));

        // inject contacts
        injectorDataSetService.injectContacts(5);

        // check the results
        assertEquals(5, contactService.findAll().size());
        assertEquals(5, registrationService.findAll().size());
    }

    @Test
    public void testInjectRegistrationSuccess() {
        // Mock call services
        byte[] idA1 = GenerateIdUtils.generateIdA();
        byte[] idA2 = GenerateIdUtils.generateIdA();
        byte[] idA3 = GenerateIdUtils.generateIdA();
        byte[] idA4 = GenerateIdUtils.generateIdA();
        byte[] idA5 = GenerateIdUtils.generateIdA();
        byte[] idA6 = GenerateIdUtils.generateIdA();
        byte[] idA7 = GenerateIdUtils.generateIdA();
        byte[] idA8 = GenerateIdUtils.generateIdA();
        byte[] idA9 = GenerateIdUtils.generateIdA();
        byte[] idA10 = GenerateIdUtils.generateIdA();

        when(generatorIdService.generateIdA())
                .thenReturn(idA1)
                .thenReturn(idA2)
                .thenReturn(idA3)
                .thenReturn(idA4)
                .thenReturn(idA5)
                .thenReturn(idA6)
                .thenReturn(idA7)
                .thenReturn(idA8)
                .thenReturn(idA9)
                .thenReturn(idA10);

        injectorDataSetService.injectRegistrations(10);
        assertEquals(10, registrationService.findAll().size());
        assertEquals(0, contactService.findAll().size());
    }
}
