package fr.gouv.stopc.robertserver.dataset.injector.service;

public interface InjectorDataSetService {

    void injectContacts(int contactCount);

    void injectRegistrations(int registrationCount);
}
