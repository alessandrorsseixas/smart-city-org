package smart.city.org.eletric.control.repositories;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import smart.city.org.eletric.control.entities.Battery;

@Repository
public interface BatteryRepository extends MongoRepository<Battery,String> {

    /*    List<Product> findByName(String name);

    @Query("{ $or: [ { name: \"CPU Ryzen 3\" }, { price: ?0 } ] }")
    List<Product> findSpecialPromo(int price);
    @Query("{'id' : ?0}")
    @Update("{'$set': {'energySource': ?1}}")
    Integer update(String id, EnergySource energySource);*/

}
