package fr.gouv.stopc.robertserver.database.repository;

import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.repository.NoRepositoryBean;
import org.springframework.data.util.StreamUtils;
import org.springframework.data.util.Streamable;
import org.springframework.util.Assert;

import fr.gouv.stopc.robertserver.database.model.Contact;

@NoRepositoryBean
public interface ContactUUIDRepository<T extends Contact, ID> extends MongoRepository<T, ID> {

	@Override
	default public <S extends T> S insert(S entity) {
		if (Objects.nonNull(entity)){
			return this.save(generateId(entity));
		}

		return entity;
	}
	
	@Override
	default	public <S extends T> List<S> insert(Iterable<S> entities) {
		if (Objects.isNull(entities)){
			return Collections.emptyList();
		}


		List<S> list = Streamable.of(entities).stream()
				.map(e -> this.generateId(e))
				.collect(StreamUtils.toUnmodifiableList());

		if (list.isEmpty()) {
			return list;
		}

		return saveAll(list);
	}

	default public <S extends T> S generateId(S entity) {

		if(Objects.nonNull(entity)){
			entity.setId(UUID.randomUUID().toString());
		}

		return entity;
	}

}
