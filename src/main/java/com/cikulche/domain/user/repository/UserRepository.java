package com.cikulche.domain.user.repository;

import com.cikulche.domain.user.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    // Spring автоматично ще напише SQL заявката: SELECT * FROM users WHERE email = ?
    Optional<User> findByEmail(String email);
}